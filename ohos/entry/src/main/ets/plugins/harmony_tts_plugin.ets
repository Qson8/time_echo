/**
 * HarmonyOS TTS Plugin for Flutter
 * 
 * 兼容性说明：
 * - 兼容 HarmonyOS SDK 12+ (API Level 12)
 * - 仅使用 Flutter 框架提供的 API，确保跨版本兼容性
 * - 不直接使用 HarmonyOS 系统 API，避免版本依赖问题
 * 
 * @since SDK 12+
 */
import { FlutterEngine, MethodChannel, MethodCall, Log } from '@ohos/flutter_ohos';

const TAG = "HarmonyTtsPlugin";
const CHANNEL_NAME = "com.time_echo/harmony_tts";

// 扩展MethodCall接口以访问argument属性
interface MethodCallWithArg extends MethodCall {
  argument?: string | number | boolean | null;
}

// 定义 TTS 客户端接口
interface TtsClient {
  init?: (callback: (err?: Error) => void) => void;
  speak?: (text: string, callback?: (err?: Error) => void) => void;
  stop?: (callback?: (err?: Error) => void) => void;
  setParameter?: (key: string, value: string) => void;
}

// 定义 TTS 参数接口
interface TtsParams {
  speed: number;
  pitch: number;
  volume: number;
  voiceType: number;
}

export class HarmonyTtsPlugin {
  private static ttsClient: TtsClient | null = null;
  private static ttsHandle: number = -1;
  private static isInitialized: boolean = false;
  private static currentSpeed: number = 1.0;
  private static currentPitch: number = 1.0;
  private static currentVolume: number = 1.0;
  private static isSpeakingFlag: boolean = false;

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
      if (HarmonyTtsPlugin.isInitialized && (HarmonyTtsPlugin.ttsClient != null || HarmonyTtsPlugin.ttsHandle !== -1)) {
        Log.i(TAG, "TTS already initialized");
        return true;
      }

      Log.i(TAG, "Initializing HarmonyOS TTS engine...");
      
      // 尝试使用系统 TTS（简化版本，不依赖特定 API）
      // 由于 ArkTS 限制，我们使用一个简化的实现
      HarmonyTtsPlugin.isInitialized = true;
      Log.i(TAG, "TTS engine initialized (simplified mode)");
      return true;
    } catch (e) {
      Log.e(TAG, "Failed to initialize TTS engine");
      HarmonyTtsPlugin.isInitialized = false;
      HarmonyTtsPlugin.ttsClient = null;
      HarmonyTtsPlugin.ttsHandle = -1;
      if (e instanceof Error) {
        throw e;
      } else {
        throw new Error("Failed to initialize TTS engine");
      }
    }
  }

  private static async speak(text: string): Promise<void> {
    try {
      if (!HarmonyTtsPlugin.isInitialized) {
        await HarmonyTtsPlugin.initialize();
      }

      if (text == null || text.length === 0) {
        Log.w(TAG, "Text is empty, skipping speak");
        return;
      }

      Log.i(TAG, "Speaking text: " + text.substring(0, Math.min(50, text.length)) + "...");
      
      // 简化实现：记录日志，实际 TTS 功能需要根据具体鸿蒙 API 实现
      HarmonyTtsPlugin.isSpeakingFlag = true;
      Log.i(TAG, "Speech started (simplified mode)");
      
      // 设置一个延迟来重置isSpeaking标志
      setTimeout(() => {
        HarmonyTtsPlugin.isSpeakingFlag = false;
      }, text.length * 100); // 粗略估计：每个字符100ms
    } catch (e) {
      Log.e(TAG, "Failed to speak");
      HarmonyTtsPlugin.isSpeakingFlag = false;
      if (e instanceof Error) {
        throw e;
      } else {
        throw new Error("Failed to speak");
      }
    }
  }

  private static async stop(): Promise<void> {
    try {
      HarmonyTtsPlugin.isSpeakingFlag = false;
      Log.i(TAG, "Speech stopped");
    } catch (e) {
      Log.e(TAG, "Failed to stop speech");
      HarmonyTtsPlugin.isSpeakingFlag = false;
      if (e instanceof Error) {
        throw e;
      } else {
        throw new Error("Failed to stop speech");
      }
    }
  }

  private static async setLanguage(language: string): Promise<void> {
    try {
      // 鸿蒙TTS会自动根据系统语言设置，这里只记录
      Log.i(TAG, "Language set to: " + language);
    } catch (e) {
      Log.e(TAG, "Failed to set language");
      if (e instanceof Error) {
        throw e;
      } else {
        throw new Error("Failed to set language");
      }
    }
  }

  private static async setSpeechRate(rate: number): Promise<void> {
    try {
      // 鸿蒙TTS的语速范围是0.5-2.0
      HarmonyTtsPlugin.currentSpeed = Math.max(0.5, Math.min(2.0, rate));
      Log.i(TAG, "Speech rate set to: " + HarmonyTtsPlugin.currentSpeed);
    } catch (e) {
      Log.e(TAG, "Failed to set speech rate");
      if (e instanceof Error) {
        throw e;
      } else {
        throw new Error("Failed to set speech rate");
      }
    }
  }

  private static async setPitch(pitch: number): Promise<void> {
    try {
      // 鸿蒙TTS的音调范围是0.5-2.0
      HarmonyTtsPlugin.currentPitch = Math.max(0.5, Math.min(2.0, pitch));
      Log.i(TAG, "Pitch set to: " + HarmonyTtsPlugin.currentPitch);
    } catch (e) {
      Log.e(TAG, "Failed to set pitch");
      if (e instanceof Error) {
        throw e;
      } else {
        throw new Error("Failed to set pitch");
      }
    }
  }

  private static async setVolume(volume: number): Promise<void> {
    try {
      // 鸿蒙TTS的音量范围是0.0-1.0
      HarmonyTtsPlugin.currentVolume = Math.max(0.0, Math.min(1.0, volume));
      Log.i(TAG, "Volume set to: " + HarmonyTtsPlugin.currentVolume);
    } catch (e) {
      Log.e(TAG, "Failed to set volume");
      if (e instanceof Error) {
        throw e;
      } else {
        throw new Error("Failed to set volume");
      }
    }
  }

  private static isSpeaking(): boolean {
    return HarmonyTtsPlugin.isSpeakingFlag;
  }
}
