import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// 枚举 上传状态 中 成功 失败
enum ImageUploadStatus { uploadInProgress, uploadSuccess, uploadFail }

// 定义回调 上传成功后
typedef UploadSuccess = Future<ImageUploadStatus> Function(File file);
// 定义回调 删除之前
typedef PreDelete = Future<bool> Function(File file);
// 定义回调 错误产生
typedef ErrorHandler = void Function(String error);

// 自制的表单图片上传控件
class FormImagePicker extends FormField<Map<File, ImageUploadStatus>> {
  // 最大上传数量
  final int imageLimit;

  // 点击删除按钮
  final PreDelete? imageDelete;

  // 上传后的动作
  final UploadSuccess? imageUpload;

  // 错误的handeler
  final ErrorHandler? onError;

  // 构造函数
  FormImagePicker({
    super.key,
    super.onSaved,
    super.validator,
    Map<File, ImageUploadStatus>? initialValue,
    bool autoValidate = false,
    int maxImageSize = 5242880, // 最大单张5m
    String? titleLabel, // 标题
    this.imageDelete, // 删除图片
    this.imageUpload, // 上传图片
    this.imageLimit = 9,
    this.onError,
  }) : super(
          // autovalidate 已废弃，改用 autovalidateMode
          autovalidateMode: autoValidate
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          initialValue: initialValue ?? <File, ImageUploadStatus>{},
          builder: (FormFieldState<Map<File, ImageUploadStatus>> state) {
            final Map<File, ImageUploadStatus> value =
                state.value ?? <File, ImageUploadStatus>{};
            // 读入局部变量，避免可空字段在闭包里无法被类型提升
            final PreDelete? deleteHandler = imageDelete;
            final UploadSuccess? uploadHandler = imageUpload;
            final ErrorHandler? errorHandler = onError;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  titleLabel ?? "上传图片（请上传清晰大图！）",
                  style: const TextStyle(color: Colors.black54),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Wrap(
                    children: value.keys.toList().map<Widget>(
                        (File pic) {
                      return FractionallySizedBox(
                        widthFactor: 0.25,
                        child: Stack(
                          children: <Widget>[
                            Container(
                              margin: const EdgeInsets.all(3.0),
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: Image.file(
                                  pic,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            value[pic] == ImageUploadStatus.uploadSuccess
                                ? Positioned(
                                    bottom: 0.0,
                                    right: 0.0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 0.0),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete_forever,
                                          color: Colors.white,
                                          size: 30.0,
                                        ),
                                        onPressed: () async {
                                          if (deleteHandler == null) return;
                                          final bool status =
                                              await deleteHandler(pic);
                                          if (status) {
                                            // 删除成功
                                            value.remove(pic);
                                            state.didChange(value);
                                          }
                                        },
                                      ),
                                    ),
                                  )
                                : FractionallySizedBox(
                                    alignment: Alignment.center,
                                    widthFactor: 1.0,
                                    child: AspectRatio(
                                      aspectRatio: 1.0,
                                      child: Opacity(
                                        opacity: 0.8,
                                        child: Container(
                                          color: Colors.grey,
                                          margin: const EdgeInsets.all(3.0),
                                          child: value[pic] ==
                                                  ImageUploadStatus
                                                      .uploadInProgress
                                              ? const CupertinoActivityIndicator()
                                              : const Icon(
                                                  Icons.info,
                                                  color: Colors.red,
                                                ),
                                        ),
                                      ),
                                    ),
                                  )
                          ],
                        ),
                      );
                    }).toList()
                      // 添加一个按钮
                      ..add(FractionallySizedBox(
                        widthFactor: 0.25,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          margin: const EdgeInsets.all(3.0),
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: value.length >= imageLimit
                                ? const SizedBox.shrink()
                                : IconButton(
                                    icon: Icon(
                                      Icons.add,
                                      color: Colors.grey.shade300,
                                    ),
                                    onPressed: () async {
                                      // image_picker 1.x：pickImage 改为实例方法，返回 XFile
                                      final XFile? picked =
                                          await ImagePicker().pickImage(
                                              source: ImageSource.gallery);
                                      if (picked == null) return;
                                      final File newImage = File(picked.path);
                                      // 判断文件大小是否超过限制
                                      if (newImage.lengthSync() > maxImageSize) {
                                        final String error =
                                            "超过图片文件大小限制！（SizeLimit:${maxImageSize / 1024 / 1024}MB）";
                                        if (errorHandler != null) {
                                          errorHandler(error);
                                        } else {
                                          throw error;
                                        }
                                        return;
                                      }
                                      // 加入文件并且挂载状态
                                      value.addAll({
                                        newImage: ImageUploadStatus
                                            .uploadInProgress
                                      });
                                      state.didChange(value);
                                      // 执行钩子
                                      if (uploadHandler != null) {
                                        final ImageUploadStatus status =
                                            await uploadHandler(newImage);
                                        // 如果传成功 修改状态到true
                                        value[newImage] = status;
                                        state.didChange(value);
                                      }
                                    }),
                          ),
                        ),
                      )),
                  ),
                ),
                state.hasError
                    ? Text(
                        state.errorText ?? '',
                        style: const TextStyle(color: Color(0xffd32f2f)),
                      )
                    : const SizedBox.shrink()
              ],
            );
          });
}
