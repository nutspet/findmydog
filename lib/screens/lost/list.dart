import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'package:find_dog/bloc/dog_bloc.dart';
import 'package:find_dog/bloc/dog_lost_bloc.dart';
import 'package:find_dog/bloc/dog_lost_event.dart';
import 'package:find_dog/models/dog_lost.dart';
import 'package:find_dog/models/dog_lost_near_by_selection.dart';
import 'package:find_dog/models/dog_lost_selection.dart';
import 'package:find_dog/models/dog_selection.dart';
import 'package:find_dog/widgets/bottom_loader.dart';

import 'lost_list_item.dart';
import 'lost_list_picker.dart';
import 'report.dart';

// 失踪汪救助中心（列表页外壳）
//
// 本次改造把这一页从「在 State 里手工维护三套 _xxxPage / _xxxEnd / _xxxList」
// 换成了 BLoC：
//   - 数据 / 分页游标 / 当前筛选 全部收敛进 DogState，页面只负责渲染
//   - 三个 tab 各自一个 bloc，互不干扰，复用同一个泛型基类 DogFetchBloc
//   - 交互按 BLoC 版行为：滑到 90% 自动加载下一页 + 下拉刷新重置，
//     去掉底部"加载更多数据"按钮
//
// 视觉（行高、字号、颜色、间距、抽屉、FAB）与改造前逐项保持一致。
class LostList extends StatefulWidget {
  const LostList({super.key});

  @override
  LostListState createState() => LostListState();
}

// SingleTickerProviderStateMixin 用来做动画
class LostListState extends State<LostList> with SingleTickerProviderStateMixin {
  // TAB控制器（在 initState 里赋值，所以用 late）
  late TabController controller;

  // 用来控制snackbar
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 进度的菊花
  final GlobalKey<RefreshIndicatorState> _refreshLatestIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _refreshTopIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _refreshNearByIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // 三个 tab 各自的 bloc。
  //
  // ⚠️ 必须由这个 State 持有，不能写成 build 里的 `BlocProvider.create`：
  // TabBarView 内部是 PageView，离开视口的子树会被销毁 ——
  // bloc 若挂在 tab 子树里，切走再切回来数据就全丢了
  // （改造前数据挂在 LostListState 上，是不会丢的）。
  final DogLostLatestFetchBloc _latestBloc = DogLostLatestFetchBloc();
  final DogLostTopFetchBloc _topBloc = DogLostTopFetchBloc();
  final DogLostNearByFetchBloc _nearByBloc = DogLostNearByFetchBloc();

  // 三个列表的滚动控制器：判断"滑到底部"，以及重置后滚回顶部
  final ScrollController _latestScroll = ScrollController();
  final ScrollController _topScroll = ScrollController();
  final ScrollController _nearByScroll = ScrollController();

  // drawer里面的彩蛋
  bool _lianDong = false;

  // 抽屉里可调的"单次请求条数"
  int _defaultPageSize = 25;

  @override
  void initState() {
    // 初始化TAB控制器
    controller = TabController(length: 3, vsync: this);
    // 加入监听 到了附近tab获取位置
    controller.addListener(_onTabChanged);

    _latestScroll.addListener(_onLatestScroll);
    _topScroll.addListener(_onTopScroll);

    // 首屏静默拉取（与改造前一致：第一次不弹 snack）
    _resetLatest();
    _resetTop();

    super.initState();
  }

  @override
  void dispose() {
    controller
      ..removeListener(_onTabChanged)
      ..dispose();
    _latestScroll
      ..removeListener(_onLatestScroll)
      ..dispose();
    _topScroll
      ..removeListener(_onTopScroll)
      ..dispose();
    _nearByScroll.dispose();
    // bloc 由本 State 手动 close（provider 用的是 .value，不会帮忙关）
    _latestBloc.close();
    _topBloc.close();
    _nearByBloc.close();
    super.dispose();
  }

  // ==================== 触发取数 ====================

  void _resetLatest() => _latestBloc
      .add(DogLostLatestFetchWithResetEvent(pageSize: _defaultPageSize));

  void _resetTop() =>
      _topBloc.add(DogLostTopFetchWithResetEvent(pageSize: _defaultPageSize));

  /// 最新的筛选变了：整体替换筛选条件并回到第一页
  void _onLatestSelectionChanged(DogLostSelection selection) {
    _latestBloc.add(DogLostLatestFetchWithResetEvent(
      selection: selection,
      pageSize: _defaultPageSize,
    ));
  }

  /// 触发一次重置，并等它真正跑完 —— 下拉刷新的转圈要一直转到数据回来。
  Future<void> _awaitFetch<
      B extends DogFetchBloc<DogFetchEventAbstract<S>, DogLost, S>,
      S extends DogSelection<S>>(B bloc, DogFetchEventAbstract<S> event) async {
    bloc.add(event);
    try {
      await bloc.stream.firstWhere(
        (DogState<DogLost, S> s) =>
            s.status == DogStatus.success || s.status == DogStatus.failure,
      );
    } catch (_) {
      // 页面已销毁 / bloc 已 close 时流会直接关闭，firstWhere 抛 StateError。
      // 静默收场，别把异常抛进 RefreshIndicator。
      return;
    }
  }

  Future<void> _refreshLatest() => _awaitFetch<DogLostLatestFetchBloc,
      DogLostSelection>(
    _latestBloc,
    DogLostLatestFetchWithResetEvent(pageSize: _defaultPageSize),
  );

  Future<void> _refreshTop() =>
      _awaitFetch<DogLostTopFetchBloc, DogLostSelection>(
        _topBloc,
        DogLostTopFetchWithResetEvent(pageSize: _defaultPageSize),
      );

  /// 附近：先拿定位，再交给 bloc。
  ///
  /// 附近接口一次给 100 条且**不分页**（线上实测 data 里只有 list、忽略 page），
  /// 所以它只有"重置"语义。
  Future<void> _refreshNearBy() async {
    try {
      final Position? position = await Geolocator.getLastKnownPosition();
      if (!mounted) return;
      // 顺带热一下 GPS：不等结果，失败了也不影响主流程（与改造前一致）
      Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).then((Position _) {}, onError: (Object e) {
        // GPS 热身失败无所谓，下面用的是 lastKnownPosition
      });
      if (position == null) {
        _showSnack("获取位置失败！请稍后重试！");
        return;
      }
      await _awaitFetch<DogLostNearByFetchBloc, DogLostNearBySelection>(
        _nearByBloc,
        DogLostNearByFetchWithResetEvent(
          selection: DogLostNearBySelection(
            longitude: position.longitude,
            latitude: position.latitude,
          ),
        ),
      );
    } catch (e) {
      _showSnack("获取位置失败！请稍后重试！");
    }
  }

  // ==================== 滚动到底 → 自动加载下一页 ====================

  void _onLatestScroll() {
    if (_isBottom(_latestScroll)) {
      _latestBloc.add(const DogLostLatestFetchEvent());
    }
  }

  void _onTopScroll() {
    if (_isBottom(_topScroll)) {
      _topBloc.add(const DogLostTopFetchEvent());
    }
  }

  /// 滑过 90% 就认为"到底了"。
  ///
  /// 防抖不在这里做：bloc 那侧给滚动事件挂了 throttle + droppable，
  /// 快速滑动即使触发很多次，也只会有一个请求真正打出去。
  bool _isBottom(ScrollController controller) {
    if (!controller.hasClients) return false;
    final double maxScroll = controller.position.maxScrollExtent;
    return controller.offset >= maxScroll * 0.9;
  }

  // ==================== 状态回调 ====================

  /// 列表状态变化时的副作用：
  /// 失败弹提示；重置成功后把列表滚回顶部。
  void _onListStateChanged<S extends DogSelection<S>>(
    DogState<DogLost, S> state,
    ScrollController scrollController,
  ) {
    if (state.status == DogStatus.failure) {
      _showSnack("错误：${state.errorMessage ?? ''}");
    }
    // reset 只在"重置"类事件产出的状态里为 true（滚动加载产出的是 false），
    // 所以这里不会在往下翻页时把列表拽回顶部。
    if (state.reset &&
        state.status == DogStatus.success &&
        scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
  }

  // 提示
  void _showSnack(String txt) {
    // ScaffoldState.showSnackBar 已在 Flutter 3.x 中移除，改用 ScaffoldMessenger。
    // 这里额外判断 mounted：回调返回时组件可能已被销毁。
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(txt),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onTabChanged() {
    // 到了附近tab获取位置（与改造前一致：切进来就重新拉一次）
    if (controller.indexIsChanging && controller.index == 2) {
      unawaited(_refreshNearBy());
    }
  }

  // ==================== 列表渲染 ====================

  Widget _buildListBody({
    required DogStatus status,
    required List<DogLost> dogs,
    required bool hasMore,
    required ScrollController scrollController,
    required String storageKey,
    required VoidCallback onRetry,
  }) {
    // 有数据就先渲染数据 —— 翻页/刷新失败时不应该把已加载的列表清空
    if (dogs.isNotEmpty) {
      return ListView.separated(
        // 这个pagestorage可以保持页面位置
        key: PageStorageKey<String>(storageKey),
        controller: scrollController,
        // 还有下一页时在末尾挂一个转圈项；滑到底自动加载，不再需要"加载更多"按钮
        itemCount: hasMore ? dogs.length + 1 : dogs.length,
        separatorBuilder: (BuildContext context, int i) => const Divider(),
        itemBuilder: (BuildContext context, int index) {
          if (index >= dogs.length) return const BottomLoader();
          return LostListItem(dog: dogs[index]);
        },
      );
    }

    // 还没出结果：首次加载 / 正在取数
    if (status == DogStatus.initial || status == DogStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 加载完了但一条都没有（或者失败且一无所有）：给个重新加载的入口
    return Center(
      child: OutlinedButton(
        onPressed: onRetry,
        child: const Text("没有数据，重新加载！"),
      ),
    );
  }

  Widget _buildLatestTab() {
    return BlocConsumer<DogLostLatestFetchBloc,
        DogState<DogLost, DogLostSelection>>(
      listenWhen: (
        DogState<DogLost, DogLostSelection> previous,
        DogState<DogLost, DogLostSelection> current,
      ) =>
          previous.status != current.status || previous.reset != current.reset,
      listener: (BuildContext context,
              DogState<DogLost, DogLostSelection> state) =>
          _onListStateChanged(state, _latestScroll),
      builder: (BuildContext context,
          DogState<DogLost, DogLostSelection> state) {
        return Column(
          children: <Widget>[
            LostListPicker(
              selection: state.selection ?? const DogLostSelection(),
              onChanged: _onLatestSelectionChanged,
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(5.0),
                child: RefreshIndicator(
                  key: _refreshLatestIndicatorKey,
                  onRefresh: _refreshLatest,
                  child: _buildListBody(
                    status: state.status,
                    dogs: state.dogs,
                    hasMore: state.hasMore,
                    scrollController: _latestScroll,
                    storageKey: "LostLatestList",
                    onRetry: _resetLatest,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopTab() {
    return BlocConsumer<DogLostTopFetchBloc,
        DogState<DogLost, DogLostSelection>>(
      listenWhen: (
        DogState<DogLost, DogLostSelection> previous,
        DogState<DogLost, DogLostSelection> current,
      ) =>
          previous.status != current.status || previous.reset != current.reset,
      listener: (BuildContext context,
              DogState<DogLost, DogLostSelection> state) =>
          _onListStateChanged(state, _topScroll),
      builder: (BuildContext context, DogState<DogLost, DogLostSelection> state) {
        return Container(
          margin: const EdgeInsets.all(5.0),
          child: RefreshIndicator(
            key: _refreshTopIndicatorKey,
            onRefresh: _refreshTop,
            child: _buildListBody(
              status: state.status,
              dogs: state.dogs,
              hasMore: state.hasMore,
              scrollController: _topScroll,
              storageKey: "LostTopList",
              onRetry: _resetTop,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNearByTab() {
    return BlocConsumer<DogLostNearByFetchBloc,
        DogState<DogLost, DogLostNearBySelection>>(
      listenWhen: (
        DogState<DogLost, DogLostNearBySelection> previous,
        DogState<DogLost, DogLostNearBySelection> current,
      ) =>
          previous.status != current.status || previous.reset != current.reset,
      listener: (BuildContext context,
              DogState<DogLost, DogLostNearBySelection> state) =>
          _onListStateChanged(state, _nearByScroll),
      builder: (BuildContext context,
          DogState<DogLost, DogLostNearBySelection> state) {
        return Container(
          margin: const EdgeInsets.all(5.0),
          child: RefreshIndicator(
            key: _refreshNearByIndicatorKey,
            onRefresh: _refreshNearBy,
            child: _buildNearByBody(state),
          ),
        );
      },
    );
  }

  Widget _buildNearByBody(DogState<DogLost, DogLostNearBySelection> state) {
    // 该接口不分页，所以永远不会"还有下一页"
    if (state.dogs.isNotEmpty) {
      return _buildListBody(
        status: state.status,
        dogs: state.dogs,
        hasMore: false,
        scrollController: _nearByScroll,
        storageKey: "LostNearByList",
        onRetry: _refreshNearBy,
      );
    }
    return switch (state.status) {
      DogStatus.initial => const Center(child: Text('获取位置中')),
      DogStatus.loading => const Center(child: CupertinoActivityIndicator()),
      DogStatus.success || DogStatus.failure => Center(
          child: OutlinedButton(
            onPressed: _refreshNearBy,
            child: const Text("没有数据，重新加载！"),
          ),
        ),
    };
  }

  // 获得tabbar
  TabBar getTabBar() {
    return TabBar(
      labelColor: Theme.of(context).secondaryHeaderColor,
      unselectedLabelColor: Theme.of(context).secondaryHeaderColor,
      labelStyle: const TextStyle(
        fontSize: 14.0,
      ),
      tabs: const <Tab>[
        Tab(
          // set icon to the tab
          text: "最新发布",
        ),
        Tab(
          text: "悬赏最高",
        ),
        Tab(
          text: "附近",
        ),
      ],
      // setup the controller
      controller: controller,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 三个 bloc 用 .value 挂上去（生命周期由本 State 管，见 dispose）。
    return MultiBlocProvider(
      providers: [
        BlocProvider<DogLostLatestFetchBloc>.value(value: _latestBloc),
        BlocProvider<DogLostTopFetchBloc>.value(value: _topBloc),
        BlocProvider<DogLostNearByFetchBloc>.value(value: _nearByBloc),
      ],
      child: Scaffold(
        key: _scaffoldKey,
        body: TabBarView(
          controller: controller,
          children: <Widget>[
            _buildLatestTab(),
            _buildTopTab(),
            _buildNearByTab(),
          ],
        ),
        appBar: AppBar(
          title: getTabBar(),
          centerTitle: true,
        ),
        // 设置放在这里
        drawer: Drawer(
          child: Container(
            color: Colors.white,
            child: ListView(
              children: <Widget>[
                Container(
                  height: 80.0,
                  margin: const EdgeInsets.all(0.0),
                  padding: const EdgeInsets.all(0.0),
                  child: DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                    ),
                    child: const Text(
                      "系统设置",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                ListTile(
                  dense: true,
                  title: const Text("重置列表"),
                  leading: const Icon(Icons.settings_backup_restore),
                  onTap: () {
                    _resetLatest();
                    _resetTop();
                    _showSnack("全部重置完毕！");
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.settings_remote),
                  title: const Text('单次请求条数'),
                  trailing: DropdownButton<int>(
                    value: _defaultPageSize,
                    isDense: true,
                    onChanged: (int? newValue) {
                      if (newValue == null) return;
                      setState(() {
                        _defaultPageSize = newValue;
                      });
                      _resetLatest();
                      _resetTop();
                      _showSnack("设置成功（$newValue条单次），并且全部重置完毕！");
                      Navigator.pop(context);
                    },
                    items: <int>[25, 45, 80]
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(
                          "$value条",
                          style: const TextStyle(fontSize: 12.0),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                ListTile(
                  dense: true,
                  title: const Text("获取位置（GPS热身）"),
                  leading: const Icon(Icons.my_location),
                  onTap: () {
                    _showSnack("已请求GPS。");
                    Geolocator.getCurrentPosition(
                            locationSettings: const LocationSettings(
                                accuracy: LocationAccuracy.high))
                        .then((Position _) {
                      _showSnack("GPS热身完成");
                    }).catchError((Object e) {
                      _showSnack("GPS热身失败");
                    });
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  dense: true,
                  value: _lianDong,
                  onChanged: (bool value) {
                    setState(() {
                      _lianDong = value;
                    });
                  },
                  title: const Text("领袖门徒模式"),
                  secondary: const Icon(Icons.landscape),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          elevation: 4.0,
          icon: const Icon(
            Icons.flash_on,
            size: 18.0,
          ),
          label: const Text(
            '立即发布',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
          ),
          onPressed: () async {
            final ReportAction? result = await Navigator.push(
              context,
              MaterialPageRoute<ReportAction>(
                builder: (context) => LostReport(),
                fullscreenDialog: true,
              ),
            );
            if (!mounted) return;
            // 如果新增成功了 刷新页面
            if (result == ReportAction.success) {
              _resetLatest();
              _resetTop();
              _showSnack("全部重置完毕！");
            }
          },
        ),
      ),
    );
  }
}
