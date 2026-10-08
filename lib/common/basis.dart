// 基础的定义
// 定义回调 成功
typedef SuccessHandler = void Function(Map<String, dynamic> data);
// 定义回调 成功（无参）
typedef SuccessVoidHandler = void Function();
// 定义回调 失败 已经转成字符串报错 方便
typedef FailHandler = void Function(String msg);
// 定义回调 完成
typedef CompleteHandler = void Function();
// 定义全局的异常控制 暂时没用到吧
typedef GlobalErrorHandler = void Function(Error error);
