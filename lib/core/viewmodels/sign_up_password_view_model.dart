
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutterchat/core/common/common_enum.dart';
import 'package:flutterchat/core/common/matrix_enum.dart';
import 'package:flutterchat/core/common/matrix_exception.dart';
import 'package:flutterchat/core/i10n/i10n.dart';
import 'package:flutterchat/core/services/localstorage_service.dart';
import 'package:flutterchat/core/services/matrix/matrix_cs_api.dart';
import 'package:flutterchat/core/viewmodels/base_view_model.dart';
import 'package:flutterchat/ui/app_route.dart';
import 'package:flutterchat/ui/views/auth_web_view.dart';
import 'package:flutterchat/ui/views/chat/chat_list.dart';

import '../../locator.dart';

class SignUpPasswordViewModel extends BaseViewModel {


  final matrixApi = locator<MatrixApi>();

  final storageService = locator<LocalStorageService>();

  /// 註冊用戶並登陸
  void signUpAndLoginAction(BuildContext context, String displayName, String username, String password, File avatar, {Map<String, dynamic> auth}) async {
    // 檢測輸入的密碼
    if (password.isEmpty) {
      setState(ViewState.Idle, errorMsg: L10n.of(context).pleaseEnterYourPassword);
      return;
    }
    try {
      // 啟動加載中
      setState(ViewState.Busy, errorMsg: null);
      // TODO
      final waitForLogin = matrixApi.loginController.stream.first;
      // 註冊用戶
      await matrixApi.register(
        username: username,
        password: password,
        initialDeviceDisplayName: storageService.user.clientName,
        auth: auth,
      );
      // 等待創建結果
      await waitForLogin;
    } on MatrixException catch (exception) {
      if (exception.requireAdditionalAuthentication) {
        final stages = exception.authenticationFlows
            .firstWhere((a) => !a.stages.contains('m.login.email.identity'))
            .stages;
        final currentStage = exception.completedAuthenticationFlows == null
            ? stages.first
            : stages.firstWhere((stage) =>
                !exception.completedAuthenticationFlows.contains(stage) ??
                true);
        if (currentStage == 'm.login.dummy') {
          signUpAndLoginAction(context, displayName, username, password, avatar, auth: {
            'type': currentStage,
            'session': exception.session,
          });
        } else {
          await Navigator.of(context).push(
            AppRoute.defaultRoute(
              context,
              AuthWebView(
                currentStage,
                exception.session,
                () => signUpAndLoginAction(context, displayName, username, password, avatar, auth: {
                  'session': exception.session,
                }),
              ),
            ),
          );
          return;
        }
        setState(ViewState.Idle, errorMsg: exception.errorMessage);
        return;
      } else {
        setState(ViewState.Idle, errorMsg: exception.errorMessage);
        return;
      }
    } catch (exception) {
      debugPrint("error: " + exception.body.toString());
      setState(ViewState.Idle, errorMsg: exception.body.toString());
      return;
    }
    // 等待登陸成功 TODO
    await matrixApi.loginController.stream
        .firstWhere((l) => l == LoginState.logged);
    // 設置顯示名
    try {
      await matrixApi.setDisplayName(storageService.user.userId, displayName);
    } catch (exception) {
      BotToast.showText(text: L10n.of(context).couldNotSetDisplayName);
    }
    // 設置頭像 TODO
//    if (avatar != null) {
//      try {
//        await matrixApi.setAvatar(
//          MatrixFile(
//            bytes: await avatar.readAsBytes(),
//            path: avatar.path,
//          ),
//        );
//      } catch (exception) {
//        BotToast.showText(text: L10n.of(context).couldNotSetAvatar);
//      }
//    }
    // 進入到聊天列表頁面
    await Navigator.of(context).pushAndRemoveUntil(
        AppRoute.defaultRoute(context, ChatListView()), (r) => false);
    // 停止加載中
    setState(ViewState.Idle);
    return;
  }
}