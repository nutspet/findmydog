// 基础的定义 其实可以用voidcallback的
// 定义回调 成功
typedef void SuccessHandler(Map<String, dynamic> data);
// 定义回调 成功
typedef void SuccessVoidHandler();
// 定义回调 失败 已经转成字符串报错 方便
typedef void FailHandler(String msg);
// 定义回调 完成
typedef void CompleteHandler();
// 定义全局的异常控制 暂时没用到吧
typedef void GlobalErrorHandler(Error error);