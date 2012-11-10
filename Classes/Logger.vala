namespace IRCBot {
	
	public class Logger : GLib.Object {
		
		public enum LogLevel { Debug, Error, Fatal, Info, Warn }
		
		public static string LogLevelString(Logger.LogLevel enuLevel){
			switch(enuLevel){
				case Logger.LogLevel.Debug:
					return "DEBUG";
				case Logger.LogLevel.Error:
					return "ERROR";
				case Logger.LogLevel.Fatal:
					return "FATAL";
				case Logger.LogLevel.Info:
					return "INFO";
				case Logger.LogLevel.Warn:
					return "WARN";
				default:
					return "INFO";
			}
		}
		
		public static void Log(string strText, LogLevel enuLevel = LogLevel.Info){
			string strLevel = LogLevelString(enuLevel);
			GLib.DateTime objDateTime = new GLib.DateTime.now_local();
			string strOut = "[" + strLevel + "][" + objDateTime.format("%H:%M:%S") + "] > " + strText;
			stdout.printf("%s%c", strOut, 10);
			if(enuLevel == LogLevel.Fatal){
				Posix.exit(0);
			}
		}
		
	}
	
}
