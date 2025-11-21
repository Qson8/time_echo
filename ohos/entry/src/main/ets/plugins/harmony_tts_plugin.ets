/**
 * HarmonyOS TTS Plugin for Flutter
 * 
 * 兼容性说明：
 * - 兼容 HarmonyOS SDK 12+ (API Level 12)
 * - 使用鸿蒙系统TTS API实现简单的语音播放功能
 * 
 * @since SDK 12+
 */
import { FlutterEngine, MethodChannel, MethodCall, Log } from '@ohos/flutter_ohos';
import { tts } from '@ohos.multimedia.tts';
import { BusinessError } from '@ohos.base';

const TAG = "HarmonyTtsPlugin";
const CHANNEL_NAME = "com.time_echo/harmony_tts";

// 扩展MethodCall接口以访问argument属性
interface MethodCallWithArg extends MethodCall {
  argument?: string | number | boolean | null;
}

export class HarmonyTtsPlugin {
  private static ttsEngine: tts.TtsEngine | null = null;
  private static isInitialized: boolean = false;
  private static currentSpeed: number = 1.0;
  private static isSpeakingFlag: boolean = false;
  private static speakTask: tts.TtsTask | null = null;

  static registerWith(flutterEngine: FlutterEngine): void {
    try {
      Log.i(TAG, "=== Starting HarmonyTtsPlugin registration ===");
      Log.i(TAG, "Channel name: " + CHANNEL_NAME);
      Log.i(TAG, "FlutterEngine.dartExecutor: " + (flutterEngine.dartExecutor ? "exists" : "null"));
      
      if (!flutterEngine.dartExecutor) {
        Log.e(TAG, "FlutterEngine.dartExecutor is null!");
        throw new Error("FlutterEngine.dartExecutor is null");
      }
      
      Log.i(TAG, "Creating MethodChannel...");
      const channel = new MethodChannel(flutterEngine.dartExecutor, CHANNEL_NAME);
      Log.i(TAG, "MethodChannel created successfully");
      
      Log.i(TAG, "Setting method call handler...");
      channel.setMethodCallHandler(HarmonyTtsPlugin.handleMethodCall);
      Log.i(TAG, "Method call handler set successfully");
      
      Log.i(TAG, "✅ HarmonyTtsPlugin registered successfully!");
      Log.i(TAG, "=== HarmonyTtsPlugin registration completed ===");
    } catch (e) {
      Log.e(TAG, "❌ Failed to register HarmonyTtsPlugin");
      if (e instanceof Error) {
        Log.e(TAG, "Error: " + e.message);
        Log.e(TAG, "Error stack: " + e.stack);
        throw e;
      } else {
        const error = new Error("Unknown error during plugin registration");
        Log.e(TAG, "Error details: " + JSON.stringify(e));
        throw error;
      }
    }
  }

  private static handleMethodCall(call: MethodCall): Promise<string | number | boolean | null> {
    try {
      const method: string = call.method;
      // 获取参数 - 使用类型安全的方式
      // 定义参数类型为基本类型的联合
      type MethodArg = string | number | boolean | null;
      let arg: MethodArg = null;
      try {
        // 通过接口扩展访问argument属性
        const callWithArg: MethodCallWithArg = call as MethodCallWithArg;
        const argumentValue: MethodArg | undefined = callWithArg.argument;
        if (argumentValue !== null && argumentValue !== undefined) {
          arg = argumentValue;
        }
      } catch (e) {
        const errorMsg: string = (e instanceof Error) ? e.message : String(e);
        Log.w(TAG, "Failed to get argument: " + errorMsg);
        arg = null;
      }
      
      switch (method) {
        case 'initialize':
          return HarmonyTtsPlugin.initialize().then((result: boolean) => result);
        case 'speak':
          if (arg !== null && typeof arg === 'string') {
            return HarmonyTtsPlugin.speak(arg).then(() => null);
          }
          return Promise.resolve(null);
        case 'stop':
          return HarmonyTtsPlugin.stop().then(() => null);
        case 'setLanguage':
          if (arg !== null && typeof arg === 'string') {
            return HarmonyTtsPlugin.setLanguage(arg).then(() => null);
          }
          return Promise.resolve(null);
        case 'setSpeechRate':
          if (arg !== null && typeof arg === 'number') {
            return HarmonyTtsPlugin.setSpeechRate(arg).then(() => null);
          }
          return Promise.resolve(null);
        case 'setPitch':
          if (arg !== null && typeof arg === 'number') {
            return HarmonyTtsPlugin.setPitch(arg).then(() => null);
          }
          return Promise.resolve(null);
        case 'setVolume':
          if (arg !== null && typeof arg === 'number') {
            return HarmonyTtsPlugin.setVolume(arg).then(() => null);
          }
          return Promise.resolve(null);
        case 'isSpeaking':
          return Promise.resolve(HarmonyTtsPlugin.isSpeaking());
        default:
          throw new Error(`Unknown method: ${method}`);
      }
    } catch (e) {
      Log.e(TAG, `Error handling method ${call.method}`);
      if (e instanceof Error) {
        Log.e(TAG, "Error: " + e.message);
        return Promise.reject(e);
      } else {
        return Promise.reject(new Error("Unknown error in handleMethodCall"));
      }
    }
  }

  private static async initialize(): Promise<boolean> {
    try {
      if (HarmonyTtsPlugin.isInitialized && HarmonyTtsPlugin.ttsEngine != null) {
        Log.i(TAG, "TTS already initialized");
        return true;
      }

      Log.i(TAG, "Initializing HarmonyOS TTS engine for simple playback...");
      
      try {
        // 创建TTS引擎实例（仅用于播放，不进行复杂合成）
        HarmonyTtsPlugin.ttsEngine = await tts.createTtsEngine();
        Log.i(TAG, "TTS engine created successfully");
        
        // 只设置基本的语速参数，使用系统默认的音量和音调
        const params: tts.TtsParams = {
          audioCapability: tts.AudioCapability.CAPABILITY_SPEED,
          speed: HarmonyTtsPlugin.currentSpeed
        };
        
        await HarmonyTtsPlugin.ttsEngine.setTtsParams(params);
        Log.i(TAG, "TTS basic parameters set successfully");
        
        HarmonyTtsPlugin.isInitialized = true;
        Log.i(TAG, "✅ TTS engine initialized for simple playback");
        return true;
      } catch (apiError) {
        Log.e(TAG, "TTS API not available");
        if (apiError instanceof BusinessError) {
          Log.e(TAG, "Error code: " + apiError.code);
          Log.e(TAG, "Error message: " + apiError.message);
        }
        HarmonyTtsPlugin.isInitialized = false;
        HarmonyTtsPlugin.ttsEngine = null;
        throw apiError;
      }
    } catch (e) {
      Log.e(TAG, "Failed to initialize TTS engine");
      HarmonyTtsPlugin.isInitialized = false;
      HarmonyTtsPlugin.ttsEngine = null;
      if (e instanceof Error) {
        throw e;
      } else {
        throw new Error("Failed to initialize TTS engine");
      }
    }
  }

  private static async speak(text: string): Promise<void> {
    try {
      if (!HarmonyTtsPlugin.isInitialized || HarmonyTtsPlugin.ttsEngine == null) {
        await HarmonyTtsPlugin.initialize();
      }

      if (text == null || text.length === 0) {
        Log.w(TAG, "Text is empty, skipping speak");
        return;
      }

      if (HarmonyTtsPlugin.ttsEngine == null) {
        Log.e(TAG, "TTS engine is null, cannot speak");
        throw new Error("TTS engine not initialized");
      }

      Log.i(TAG, "Playing text: " + text.substring(0, Math.min(50, text.length)) + "...");
      
      // 如果正在播放，先停止
      if (HarmonyTtsPlugin.isSpeakingFlag && HarmonyTtsPlugin.speakTask != null) {
        try {
          await HarmonyTtsPlugin.ttsEngine.stop(HarmonyTtsPlugin.speakTask);
          Log.i(TAG, "Stopped previous speech");
        } catch (e) {
          Log.w(TAG, "Failed to stop previous speech: " + e);
        }
      }
      
      // 开始语音播放（使用系统默认设置，不进行复杂合成）
      HarmonyTtsPlugin.isSpeakingFlag = true;
      
      // 创建简单的TTS任务
      const ttsTask: tts.TtsTask = {
        text: text,
        range: {
          start: 0,
          end: text.length
        }
      };
      
      HarmonyTtsPlugin.speakTask = ttsTask;
      
      // 设置播放完成回调
      HarmonyTtsPlugin.ttsEngine.on('ttsFinish', () => {
        Log.i(TAG, "TTS playback finished");
        HarmonyTtsPlugin.isSpeakingFlag = false;
        HarmonyTtsPlugin.speakTask = null;
      });
      
      // 设置播放错误回调
      HarmonyTtsPlugin.ttsEngine.on('ttsError', (err: BusinessError) => {
        Log.e(TAG, "TTS playback error: " + err.message);
        HarmonyTtsPlugin.isSpeakingFlag = false;
        HarmonyTtsPlugin.speakTask = null;
      });
      
      // 开始播放
      await HarmonyTtsPlugin.ttsEngine.speak(ttsTask);
      Log.i(TAG, "✅ Speech playback started");
    } catch (e) {
      Log.e(TAG, "Failed to play speech");
      HarmonyTtsPlugin.isSpeakingFlag = false;
      HarmonyTtsPlugin.speakTask = null;
      if (e instanceof BusinessError) {
        Log.e(TAG, "Error code: " + e.code);
        Log.e(TAG, "Error message: " + e.message);
      }
      throw e;
    }
  }

  private static async stop(): Promise<void> {
    try {
      if (HarmonyTtsPlugin.ttsEngine != null && HarmonyTtsPlugin.speakTask != null) {
        await HarmonyTtsPlugin.ttsEngine.stop(HarmonyTtsPlugin.speakTask);
        Log.i(TAG, "Speech stopped successfully");
      }
      HarmonyTtsPlugin.isSpeakingFlag = false;
      HarmonyTtsPlugin.speakTask = null;
    } catch (e) {
      Log.e(TAG, "Failed to stop speech");
      if (e instanceof BusinessError) {
        Log.e(TAG, "Error code: " + e.code);
        Log.e(TAG, "Error message: " + e.message);
      }
      HarmonyTtsPlugin.isSpeakingFlag = false;
      HarmonyTtsPlugin.speakTask = null;
      if (e instanceof Error) {
        throw e;
      } else {
        throw new Error("Failed to stop speech");
      }
    }
  }

  private static async setLanguage(language: string): Promise<void> {
    try {
      // 使用系统默认语言，不进行额外设置
      Log.i(TAG, "Language will use system default: " + language);
    } catch (e) {
      Log.w(TAG, "Language setting ignored: " + e);
    }
  }

  private static async setSpeechRate(rate: number): Promise<void> {
    try {
      // 鸿蒙TTS的语速范围是0.5-2.0
      HarmonyTtsPlugin.currentSpeed = Math.max(0.5, Math.min(2.0, rate));
      Log.i(TAG, "Speech rate set to: " + HarmonyTtsPlugin.currentSpeed);
      
      // 如果TTS引擎已初始化，更新语速参数
      if (HarmonyTtsPlugin.isInitialized && HarmonyTtsPlugin.ttsEngine != null) {
        const params: tts.TtsParams = {
          audioCapability: tts.AudioCapability.CAPABILITY_SPEED,
          speed: HarmonyTtsPlugin.currentSpeed
        };
        await HarmonyTtsPlugin.ttsEngine.setTtsParams(params);
        Log.i(TAG, "Speech rate updated");
      }
    } catch (e) {
      Log.e(TAG, "Failed to set speech rate");
      if (e instanceof BusinessError) {
        Log.e(TAG, "Error code: " + e.code);
        Log.e(TAG, "Error message: " + e.message);
      }
      // 不抛出异常，允许继续使用默认语速
    }
  }

  private static async setPitch(pitch: number): Promise<void> {
    try {
      // 音调功能已移除，仅保留基本播放
      Log.i(TAG, "Pitch setting not supported in simple playback mode");
    } catch (e) {
      Log.w(TAG, "Pitch setting ignored: " + e);
    }
  }

  private static async setVolume(volume: number): Promise<void> {
    try {
      // 音量功能已移除，使用系统默认音量
      Log.i(TAG, "Volume setting not supported in simple playback mode, using system default");
    } catch (e) {
      Log.w(TAG, "Volume setting ignored: " + e);
    }
  }

  private static isSpeaking(): boolean {
    return HarmonyTtsPlugin.isSpeakingFlag;
  }
}
