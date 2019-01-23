import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

// 枚举 上传状态 中 成功 失败
enum ImageUploadStatus { UPLOAD_IN_PROGRESS, UPLOAD_SUCCESS, UPLOAD_FAIL }

// 定义回调 上传成功后
typedef Future<ImageUploadStatus> UploadSuccess(File file);
// 定义回调 删除之前
typedef Future<bool> PreDelete(File file);
// 定义回调 错误产生
typedef void ErrorHandler(String error);

// 自制的表单图片上传控件
class FormImagePicker extends FormField<Map<File, ImageUploadStatus>> {
  // 最大上传数量
  final int imageLimit;

  // 点击删除按钮
  final PreDelete imageDelete;

  // 上传后的动作
  final UploadSuccess imageUpload;

  // 错误的handeler
  final ErrorHandler onError;

  // 构造函数
  FormImagePicker({
    Key key,
    FormFieldSetter<Map<File, ImageUploadStatus>> onSaved,
    FormFieldValidator<Map<File, ImageUploadStatus>> validator,
    Map<File, ImageUploadStatus> initialValue,
    bool autoValidate = false,
    int maxImageSize = 5242880, // 最大单张5m
    String titleLabel, // 标题
    this.imageDelete, // 删除图片
    this.imageUpload, // 上传图片
    this.imageLimit = 9,
    this.onError,
  }) : super(
            key: key,
            onSaved: onSaved,
            validator: validator,
            autovalidate: autoValidate,
            initialValue: initialValue == null
                ? new Map<File, ImageUploadStatus>()
                : initialValue,
            builder: (FormFieldState<Map<File, ImageUploadStatus>> state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    titleLabel ?? "上传图片（请上传清晰大图！）",
                    style: TextStyle(color: Colors.black54),
                  ),
                  Divider(),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Wrap(
                      children: state.value.keys.toList().map<Widget>(
                          (File pic) {
                        return FractionallySizedBox(
                          child: Stack(
                            children: <Widget>[
                              Container(
                                child: AspectRatio(
                                  aspectRatio: 1.0,
                                  child: Image.file(
                                    pic,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                margin: EdgeInsets.all(3.0),
                              ),
                              state.value[pic] ==
                                      ImageUploadStatus.UPLOAD_SUCCESS
                                  ? Positioned(
                                      child: Container(
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.delete_forever,
                                            color: Colors.white,
                                            size: 30.0,
                                          ),
                                          onPressed: () async {
                                            bool status =
                                                await imageDelete(pic);
                                            if (status) {
                                              // 删除成功
                                              state.value.remove(pic);
                                              state.didChange(state.value);
                                            }
                                          },
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 0.0),
                                      ),
                                      bottom: 0.0,
                                      right: 0.0,
                                    )
                                  : FractionallySizedBox(
                                      child: AspectRatio(
                                        aspectRatio: 1.0,
                                        child: Opacity(
                                          opacity: 0.8,
                                          child: Container(
                                            color: Colors.grey,
                                            margin: EdgeInsets.all(3.0),
                                            child: state.value[pic] ==
                                                    ImageUploadStatus
                                                        .UPLOAD_IN_PROGRESS
                                                ? CupertinoActivityIndicator()
                                                : Icon(
                                                    Icons.info,
                                                    color: Colors.red,
                                                  ),
                                          ),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      // heightFactor: 1.0,
                                      widthFactor: 1.0,
                                    )
                            ],
                          ),
                          widthFactor: 0.25,
                        );
                      }).toList()
                        // 添加一个按钮
                        ..add(FractionallySizedBox(
                          child: Container(
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: state.value.length >= imageLimit
                                  ? Container()
                                  : IconButton(
                                      icon: Icon(
                                        Icons.add,
                                        color: Colors.grey.shade300,
                                      ),
                                      onPressed: () async {
                                        File newImage =
                                            await ImagePicker.pickImage(
                                                source: ImageSource.gallery);
                                        if (newImage != null) {
                                          // 判断文件大小是否超过限制
                                          if (newImage.lengthSync() >
                                              maxImageSize) {
                                            //state. = "超过图片大小";
                                            String error =
                                                "超过图片文件大小限制！（SizeLimit:${maxImageSize / 1024 / 1024}MB）";
                                            if (onError != null) {
                                              return onError(error);
                                            } else {
                                              throw error;
                                            }
                                          }
                                          // 加入文件并且挂载状态
                                          state.value.addAll({
                                            newImage: ImageUploadStatus
                                                .UPLOAD_IN_PROGRESS
                                          });
                                          state.didChange(state.value);
                                          // 执行钩子
                                          if (imageUpload != null) {
                                            ImageUploadStatus status =
                                                await imageUpload(newImage);
                                            // 如果传成功 修改状态到true
                                            state.value[newImage] = status;
                                            state.didChange(state.value);
                                          }
                                        }
                                      }),
                            ),
                            decoration: new BoxDecoration(
                              // color: Colors.grey.shade300,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            margin: EdgeInsets.all(3.0),
                          ),
                          widthFactor: 0.25,
                        )),
                    ),
                  ),
                  state.hasError
                      ? Text(
                          state.errorText,
                          style: TextStyle(color: Color(0xffd32f2f)),
                        )
                      : Container()
                ],
              );
            });
}
