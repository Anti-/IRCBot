namespace IRCBot {
	
	class BotBase : GLib.Object {
		
		public GLib.Resolver objResolver;
		public GLib.SocketClient objSocket;
		public GLib.SocketConnection objConnection;
		public Gee.HashMap<string, string> mapConfig;
		public string strNickname;
		public string strLastCommandChannel;
		private GLib.DataInputStream objInputStream;
		private GLib.DataOutputStream objOutputStream;
		private GLib.KeyFile objKeyFile;
		
		construct {
			this.Config = new Gee.HashMap<string, string>();
			this.objKeyFile = new GLib.KeyFile();
			try {
				this.Resolver = GLib.Resolver.get_default();
				this.Socket = new GLib.SocketClient();
				this.FileParser.load_from_file("Settings.conf", GLib.KeyFileFlags.NONE);
				this.Config["Address"] = this.FileParser.get_value("Network", "Address");
				this.Config["Channel"] = this.FileParser.get_value("Network", "Channel");
				this.Config["Port"] = this.FileParser.get_value("Network", "Port");
				this.Config["Real"] = this.FileParser.get_value("Bot", "Real");
				this.Config["SSL"] = this.FileParser.get_value("Network", "SSL");
				this.Config["User"] = this.FileParser.get_value("Bot", "User");
				this.Nickname = this.FileParser.get_value("Bot", "Nick");
			} catch(GLib.Error objError){
				Logger.Log(objError.message, Logger.LogLevel.Fatal);
			}
		}
		
		public GLib.SocketConnection Connection {
			get { return this.objConnection; }
			set { this.objConnection = value; }
		}
		
		public Gee.HashMap<string, string> Config {
			get { return this.mapConfig; }
			set { this.mapConfig = value; }
		}
		
		public GLib.DataInputStream InputStream {
			get { return this.objInputStream; }
			set { this.objInputStream = value; }
		}
		
		public string Nickname {
			get { return this.strNickname; }
			set { this.strNickname = value; }
		}
		
		public string lastCommandChannel {
			get { return this.strLastCommandChannel; }
			set { this.strLastCommandChannel = value; }
		}
		
		public GLib.DataOutputStream OutputStream {
			get { return this.objOutputStream; }
			set { this.objOutputStream = value; }
		}
		
		public GLib.KeyFile FileParser {
			get { return this.objKeyFile; }
		}
		
		public GLib.Resolver Resolver {
			get { return this.objResolver; }
			set { this.objResolver = value; }
		}
		
		public GLib.SocketClient Socket {
			get { return this.objSocket; }
			set { this.objSocket = value; }
		}
		
		// Method for building strings from string[]
		public virtual string buildString(string[] arrData, int intStart = 3, bool blnCommand = false){
			GLib.StringBuilder objStringBuild = new GLib.StringBuilder();
			for(int intChar = intStart; intChar < arrData.length; intChar++){
				objStringBuild.append((intChar == intStart ? "" : " ") + (intChar == intStart ? arrData[intChar].substring(blnCommand == false ? 1 : 0) : arrData[intChar]));
			}
			return objStringBuild.str;
		}
		
		// TODO: Add error handling (i.e nickname already in use, maybe can be done in parseData)
		public virtual void changeNick(string strNickname){
			this.sendData("NICK " + strNickname);
		}
		
		// TODO: Add error handling (i.e invite only, maybe can be done in parseData)
		public virtual void joinChannel(string strChannel){
			this.sendData("JOIN " + strChannel);
		}
		
		public virtual void netConnect(string strHost, string intPort){
			bool blnSSL = this.Config["SSL"] == "true" ? true : false;
			Logger.Log("Connecting to " + strHost + ":" + (blnSSL ? "+" : "") + intPort);
			GLib.InetAddress strAddress;
			GLib.List<GLib.InetAddress> objAddresses;
			try {
				objAddresses = this.objResolver.lookup_by_name(this.Config["Address"]);
				strAddress = objAddresses.nth_data(0);
				if(blnSSL == true){
					this.Socket.set_tls(true);
					this.Socket.set_tls_validation_flags(0);
				}
				this.Connection = this.Socket.connect(new GLib.InetSocketAddress(strAddress, (uint16)int.parse(intPort)));
				this.InputStream = new GLib.DataInputStream(this.Connection.input_stream);
				this.OutputStream = new GLib.DataOutputStream(this.Connection.output_stream);
			} catch(GLib.Error objError){
				Logger.Log("Unable to establish connection: " + objError.message, Logger.LogLevel.Fatal);
			}
			Logger.Log("Successfully established connection");
			Logger.Log("Beggining authorization of bot");
			this.changeNick(this.Nickname);
			this.sendData("USER " + this.Nickname + " nig nog :" + this.Config["User"]);
		}
		
		public virtual void handleCommand(string strFrom, string strMessage){
			Logger.Log("You *must* override the handleCommand method in IRCBot.BotBase", Logger.LogLevel.Fatal);
		}
		
		public virtual void parseData(string strData){
			string[] arrData;
			arrData = strData.split(" ");
			if(arrData[0] == "PING"){
				this.sendData("PONG " + arrData[1]);
			} else if(arrData[1] == ":Closing" && arrData[2] == "Link:"){
				Logger.Log("Remote host closed connection");
				try {
					this.Connection.close();
				} catch(GLib.IOError objError){
					Logger.Log(objError.message, Logger.LogLevel.Error);
				}
			} else if(int.parse(arrData[1]) == 005){
				this.joinChannel(this.Config["Channel"]);
			} else if(int.parse(arrData[1]) == 332){
				Logger.Log("Topic for " + arrData[3] + " is " + this.buildString(arrData, 4));
			} else if(arrData[1] == "NICK"){
				string[] arrUser = arrData[0].split("!");
				Logger.Log(this.Nickname);
				Logger.Log(arrUser[0].substring(1));
				if(arrUser[0].substring(1) == this.Nickname){
					this.sendMessage(this.lastCommandChannel, "Successfully changed nick to " + arrData[2]);
					this.Nickname = arrData[2];
					Logger.Log("Changed nick to " + this.Nickname);
				} else {
					Logger.Log(arrUser[0].substring(1) + " changed their nick to " + arrData[2]);
				}
			} else if(arrData[1] == "TOPIC"){
				Logger.Log("Topic for " + arrData[2] + " changed to " + this.buildString(arrData) + " by " + arrData[0]);
			} else if(arrData[1] == "PRIVMSG"){
				string strMessage = this.buildString(arrData);
				bool blnCommand = strMessage.substring(0, 1) == "!" ? true : false;
				if(blnCommand){
					this.handleCommand(arrData[2], strMessage);
				} else {
					Logger.Log("Received message: " + strMessage);
				}
			}
		}
		
		public virtual void recvData(){
			string? strData = null;
			try {
				strData = this.InputStream.read_line(null);
			} catch(GLib.IOError objError){
				Logger.Log(objError.message, Logger.LogLevel.Error);
			}
			if(strData != null){
				Logger.Log("Received data: " + strData, Logger.LogLevel.Debug);
				this.parseData(strData);
			}
		}
		
		public virtual void sendData(string strData){
			try {
				this.OutputStream.put_string(strData + "\r\n");
			} catch(GLib.IOError objError){
				Logger.Log(objError.message, Logger.LogLevel.Error);
			}
		//	Logger.Log("Sending data: " + strData, Logger.LogLevel.Debug);
		}
		
		public virtual void sendMessage(string strChannel, string strMessage){
			this.sendData("PRIVMSG " + strChannel + " :" + strMessage);
		}
		
	}
	
}
