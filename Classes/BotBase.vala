namespace IRCBot {
	
	class BotBase : GLib.Object {
		
		public GLib.Resolver objResolver;
		public GLib.SocketClient objSocket;
		public GLib.SocketConnection objConnection;
		public Gee.ArrayList<string> lstArgumentBlackList;
		public Gee.HashMap<string, string> mapConfig;
		public string strNickname;
		public string strLastCommandChannel;
		private GLib.DataInputStream objInputStream;
		private GLib.DataOutputStream objOutputStream;
		private GLib.KeyFile objKeyFile;
		
		construct {
			this.lstArgumentBlackList = new Gee.ArrayList<string>();
			this.mapConfig = new Gee.HashMap<string, string>();
			this.objKeyFile = new GLib.KeyFile();
			try {
				this.objResolver = GLib.Resolver.get_default();
				this.objSocket = new GLib.SocketClient();
				this.loadConfig();
			} catch(GLib.Error objError){
				Logger.Log(objError.message, Logger.LogLevel.Fatal);
			}
		}
		
		public void loadConfig(){
			try {
				this.objKeyFile.load_from_file("Settings.conf", GLib.KeyFileFlags.NONE);
				this.mapConfig["Address"] = this.objKeyFile.get_value("Network", "Address");
				this.mapConfig["Channel"] = this.objKeyFile.get_value("Network", "Channel");
				this.mapConfig["MusixAPI"] = this.objKeyFile.get_value("Other", "MusixMatch");
				this.mapConfig["Pass"] = this.objKeyFile.get_value("Bot", "Pass");
				this.mapConfig["Port"] = this.objKeyFile.get_value("Network", "Port");
				this.mapConfig["PHPFile"] = this.objKeyFile.get_value("Other", "PHPFile");
				this.mapConfig["Real"] = this.objKeyFile.get_value("Bot", "Real");
				this.mapConfig["SSL"] = this.objKeyFile.get_value("Network", "SSL");
				this.mapConfig["User"] = this.objKeyFile.get_value("Bot", "User");
				this.strNickname = this.objKeyFile.get_value("Bot", "Nick");
				string[] arrBlacklist = this.objKeyFile.get_value("Other", "ArgumentBlackList").split("|");
				this.lstArgumentBlackList = new Gee.ArrayList<string>();
				for(int intCount = 0; intCount < arrBlacklist.length; intCount++){
					this.lstArgumentBlackList.add(arrBlacklist[intCount]);
				}
			} catch(GLib.Error objError){
				Logger.Log(objError.message, Logger.LogLevel.Fatal);
			}
		}
		
		public Gee.ArrayList<string> ArgumentBlackList {
			get { return this.lstArgumentBlackList; }
		}
		
		public GLib.SocketConnection Connection {
			get { return this.objConnection; }
		}
		
		public Gee.HashMap<string, string> Config {
			get { return this.mapConfig; }
		}
		
		public GLib.DataInputStream InputStream {
			get { return this.objInputStream; }
		}

		public string Nickname {
			get { return this.strNickname; }
		}
		
		public string lastCommandChannel {
			get { return this.strLastCommandChannel; }
			set { this.strLastCommandChannel = value; }
		}
		
		public GLib.DataOutputStream OutputStream {
			get { return this.objOutputStream; }
		}
		
		public GLib.Resolver Resolver {
			get { return this.objResolver; }
		}
		
		public GLib.SocketClient Socket {
			get { return this.objSocket; }
		}
		
		public virtual string buildString(string[] arrData, int intStart = 3, bool blnCommand = false){
			GLib.StringBuilder objStringBuild = new GLib.StringBuilder();
			for(int intChar = intStart; intChar < arrData.length; intChar++){
				objStringBuild.append((intChar == intStart ? "" : " ") + (intChar == intStart ? arrData[intChar].substring(blnCommand == false ? 1 : 0) : arrData[intChar]));
			}
			return objStringBuild.str;
		}
		
		public virtual void changeNick(string strNickname){
			this.sendData("NICK " + strNickname);
		}
		
		public virtual bool detectPrivateMessage(string strFrom){
			if(strFrom.substring(0, 1) != "#") return true;
			return false;
		}
		
		public virtual string extractNickname(string[] arrData){
			string[] arrUser = arrData[0].split("!");
			return arrUser[0].substring(1);
		}
		
		public string googleTranslate(string strText, string strFromLang = "en", string strToLang = "es") throws GLib.Error {
			string strUri = "http://ajax.googleapis.com/ajax/services/language/translate";
			string strVersion = "1.0";
			string strFullUri = "%s?v=%s&q=%s&langpair=%s|%s".printf(strUri, strVersion, Soup.URI.encode(strText, null), strFromLang, strToLang);
			var objSession = new Soup.SessionAsync();
			var objMessage = new Soup.Message("GET", strFullUri);
			objSession.send_message(objMessage);
			Json.Parser objParser = new Json.Parser();
			objParser.load_from_data((string)objMessage.response_body.flatten().data, -1);
			var objRoot = objParser.get_root().get_object();
			string strTranslated = objRoot.get_object_member("responseData").get_string_member("translatedText");
			return strTranslated;
		}
		
		public virtual void sendIdentify(string strPassword){
			this.sendData("NICKSERV IDENTIFY " + strPassword);
		}
		
		public virtual void joinChannel(string strChannel){
			this.sendData("JOIN " + strChannel);
		}
		
		public virtual void* handleCommand(string strFrom, string strMessage, string[] arrFull = {}){
			Logger.Log("handleCommand must be overridden in a sub-class!", Logger.LogLevel.Fatal);
			return null;
		}
		
		public virtual void netConnect(string strHost, string intPort){
			bool blnSSL = this.mapConfig["SSL"] == "true" ? true : false;
			Logger.Log("Connecting to " + strHost + ":" + (blnSSL ? "+" : "") + intPort);
			GLib.InetAddress strAddress;
			GLib.List<GLib.InetAddress> objAddresses;
			try {
				objAddresses = this.objResolver.lookup_by_name(this.mapConfig["Address"]);
				strAddress = objAddresses.nth_data(0);
				if(blnSSL == true){
					this.objSocket.set_tls(true);
					this.objSocket.set_tls_validation_flags(0);
				}
				this.objConnection = this.objSocket.connect(new GLib.InetSocketAddress(strAddress, (uint16)int.parse(intPort)));
				this.objInputStream = new GLib.DataInputStream(this.objConnection.input_stream);
				this.objOutputStream = new GLib.DataOutputStream(this.objConnection.output_stream);
			} catch(GLib.Error objError){
				Logger.Log("Unable to establish connection: " + objError.message, Logger.LogLevel.Fatal);
			}
			Logger.Log("Successfully established connection");
			Logger.Log("Beggining authorization of bot");
			this.changeNick(this.strNickname);
			this.sendData("USER " + this.strNickname + " nig nog :" + this.mapConfig["User"]);
		}
		
		public virtual void parseData(string strData){
			string[] arrData = strData.split(" ");
			if(arrData[0] == "PING"){
				this.sendData("PONG " + arrData[1]);
			} else if(arrData[1].down() == ":closing" && arrData[2].down() == "link:"){
				Logger.Log("Remote host closed connection");
				try {
					this.objConnection.close();
				} catch(GLib.IOError objError){
					Logger.Log(objError.message, Logger.LogLevel.Error);
				}
			} else if(int.parse(arrData[1]) == 005){
				if(this.mapConfig["Pass"] != ""){
					this.sendIdentify(this.mapConfig["Pass"]);
				}
				this.joinChannel(this.mapConfig["Channel"]);
			} else if(int.parse(arrData[1]) == 332){
				Logger.Log("Topic for " + arrData[3] + " is " + this.buildString(arrData, 4));
			} else if(int.parse(arrData[1]) == 432){
				this.sendMessage(this.strLastCommandChannel, "Could not change nick to " + arrData[3] + " (" + this.buildString(arrData, 4) + ")");
			} else if(int.parse(arrData[1]) == 473){
				this.sendMessage(this.strLastCommandChannel, "Could not join channel.");
			} else if(int.parse(arrData[1]) == 926){
				this.sendMessage(this.strLastCommandChannel, "Could not join channel.");
			} else if(arrData[1] == "NICK"){
				string strNick = this.extractNickname(arrData);
				if(strNick == this.strNickname){
					this.sendMessage(this.strLastCommandChannel, "Successfully changed nick to " + arrData[2]);
					this.strNickname = arrData[2].chomp();
					Logger.Log("Changed nick to " + this.strNickname);
				} else {
					Logger.Log(strNick + " changed their nick to " + arrData[2]);
				}
			} else if(arrData[1] == "TOPIC"){
				Logger.Log("Topic for " + arrData[2] + " changed to \"" + this.buildString(arrData).strip() + "\" by " + arrData[0].substring(1));
			} else if(arrData[1] == "PRIVMSG"){
				string strMessage = this.buildString(arrData);
				bool blnCommand = strMessage.substring(0, 1) == "!" ? true : false;
				bool blnPrivate = this.detectPrivateMessage(arrData[2]);
				string strFrom = blnPrivate ? this.extractNickname(arrData) : arrData[2];
				if(blnCommand){
					new GLib.Thread<void*>("CommandHandler", () => {
						return this.handleCommand(strFrom, strMessage, arrData);
					});
				} else {
					Logger.Log("Received message: " + strMessage);
					if(strMessage.index_of("https://www.youtube.com/watch?v=") > -1 || strMessage.index_of("http://www.youtube.com/watch?v=") > -1){
						string[] arrUID = strMessage.split("v=");
						string strUID = arrUID[1];
						if(strUID.index_of(" ") > -1){
							string[] arrSplit = strUID.split(" ");
							strUID = arrSplit[0];
						}
						string strPage = Utils.fetch("http://www.youtube.com/watch?v=" + strUID);
						string strTitle = Utils.getBetween(strPage, "<meta name=\"description\" content=\"", "\">");
						this.sendMessage(arrData[2], strTitle);
					}
				}
			}
		}
		
		public virtual void recvData(){
			string? strData = null;
			try {
				strData = this.objInputStream.read_line(null);
			} catch(GLib.IOError objError){
				Logger.Log(objError.message, Logger.LogLevel.Error);
			}
			if(strData != null){
				Logger.Log("Received data: " + strData, Logger.LogLevel.Debug);
				this.parseData(strData);
			}
		}
		
		public virtual bool scanBlacklist(string strText, bool blnIndex = false){
			foreach(string strBlack in this.lstArgumentBlackList){
				if(strText.down() == strBlack.down()){
					return true;
				} else if(blnIndex == true && strText.down().index_of(strBlack.down()) > -1){
					return true;
				}
			}
			return false;
		}
		
		public virtual void sendData(string strData){
			try {
				this.objOutputStream.put_string(strData + "\r\n");
			} catch(GLib.IOError objError){
				Logger.Log(objError.message, Logger.LogLevel.Error);
			}
			Logger.Log("Sending data: " + strData, Logger.LogLevel.Debug);
		}
		
		public virtual void sendMessage(string strChannel, string strMessage){
			this.sendData("PRIVMSG " + strChannel + " :" + strMessage);
		}
		
		public virtual void sendQuit(string strQuitMessage = "Leaving"){
			this.sendData("QUIT " + strQuitMessage);
		}
		
	}
	
}
