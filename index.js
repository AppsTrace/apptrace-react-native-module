import {
  NativeModules,
  NativeEventEmitter,
  EmitterSubscription,
} from 'react-native';

const ApptraceModule = NativeModules.ApptraceModule;
const eventEmitter = new NativeEventEmitter(ApptraceModule);

var nativeEventSubscription = null;
var registerWakeUpCallback = null;

export default class Apptrace {
   /**
   * 初始化Apptrace
   */
  static init(enableClipboard = true) {
    ApptraceModule.initSDK(enableClipboard);
  }

  /**
   * 获取安装参数，默认请求超时为10秒
   * @param {Function} callback = (result）=> {}
   */
  static getInstall(callback) {
    if (null == callback) {
        return;
    }

    ApptraceModule.getInstall(result => {
      callback(result);
    });
  }

  /**
   * 订阅获取universal link或scheme一键调起的参数
   * @param {Function} callback = (result）=> {}
   */
  static registerWakeUp(callback) {
    if (null == callback) {
        return;
    }

    registerWakeUpCallback = callback;

    ApptraceModule.registerWakeUp(result => {
      callback(result);
    });

    if (null == nativeEventSubscription) {
      nativeEventSubscription = eventEmitter.addListener(
        'ApptraceWakeUpEvent',
        result => {
            registerWakeUpCallback(result);
        },
      );
    }
  }

  /**
   * 取消订阅获取universal link或scheme一键调起的参数
   */
  static unRegisterWakeUp() {
    if (null != nativeEventSubscription) {
        nativeEventSubscription.remove();
        nativeEventSubscription = null;

        registerWakeUpCallback = null;
    }
  }
}
