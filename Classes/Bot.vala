namespace IRCBot {
	
	class Bot : BotBase {
		
		public override void handleCommand(string strFrom, string strMessage){
			string[] arrData = strMessage.split(" ");
			string strCommand = arrData[0].substring(1);
			Logger.Log("Received command: " + strCommand);
			switch(strCommand.up().chomp()){
				case "DIE":
					this.sendMessage(strFrom, "Shutting down");
					this.sendQuit("!DIE command used");
					Logger.Log("!DIE command used");
					try {
						this.Connection.close();
					} catch(GLib.IOError objError){
						Logger.Log(objError.message, Logger.LogLevel.Error);
						Posix.exit(0);
						break;
					}
				break;
				case "FACT":
					string strFacts;
					try {
						GLib.FileUtils.get_contents("Facts", out strFacts);
					} catch(GLib.FileError objError){
						Logger.Log(objError.message);
						this.sendMessage(strFrom, "Facts file not found");
						break;
					}
					string[] arrFacts = strFacts.split("\n");
					this.sendMessage(strFrom, arrFacts[GLib.Random.int_range(0, arrFacts.length)]);
				break;
				case "GOOGLE":
				//	string strResult = Utils.fetch("http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=" + this.buildString(arrData, 0, true).replace(" ", "+").chomp() + "&userip=lol");
					var objSession = new Soup.SessionAsync();
					var objMessage = new Soup.Message("GET", "http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=" + this.buildString(arrData, 0, true).replace(" ", "+").chomp() + "&userip=lol");
					objSession.send_message(objMessage);
					Json.Parser objParser = new Json.Parser();
					try {
						objParser.load_from_data((string)objMessage.response_body.flatten().data, -1);
					} catch(GLib.Error objError){
						Logger.Log(objError.message);
						this.sendMessage(strFrom, objError.message);
					}
					Json.Object objRoot = objParser.get_root().get_object();
					var objMember = objRoot.get_object_member("responseData");
					var objMemberResult = objMember.get_array_member("results");
					foreach(var objNode in objMemberResult.get_elements()){
						var objClass = objNode.get_object();
						this.sendMessage(strFrom, objClass.get_string_member("titleNoFormatting") + " - " + objClass.get_string_member("unescapedUrl"));
					}
				//	string strResult = objRoot.get_object_member("responseData").get_string_member("unescapedUrl");
				//	this.sendMessage(strFrom, strResult);
				break;
				case "JOIN":
					this.joinChannel(arrData[1]);
				break;
				case "NICK":
					string strNick = arrData[1].chomp();
					if(this.scanBlacklist(strNick)){
						this.sendMessage(strFrom, "Denied");
						break;
					}
					this.changeNick(strNick);
				break;
				case "RELOAD":
					this.loadConfig();
					this.sendMessage(strFrom, "Configuration reloaded");
				break;
				case "SAY":
					string strReply = this.buildString(arrData, 1, true);
					this.sendMessage(strFrom, strReply);
				break;
				case "SING":
					string strLyricFile = arrData[1].chomp();
					bool blnBlacklisted = this.scanBlacklist(strLyricFile, true);
					if(blnBlacklisted){
						this.sendMessage(strFrom, "Denied");
						break;
					}
					string strLyrics;
					try {
						GLib.FileUtils.get_contents("Lyrics/" + strLyricFile, out strLyrics);
					} catch(GLib.FileError objError){
						Logger.Log(objError.message, Logger.LogLevel.Error);
						this.sendMessage(strFrom, objError.message);
						break;
					}
					string[] arrLyrics = strLyrics.split("\n");
					for(int intLyric = 0; intLyric < arrLyrics.length; intLyric++){
						this.sendMessage(strFrom, arrLyrics[intLyric]);
					}
				break;
				case "TRANSLATE":
					string strText = arrData[1].chomp();
					string strInputLang = arrData[2].chomp();
					string strOutputLang = arrData[3].chomp();
					string strTranslation = "";
					Logger.Log("Attempting translation: " + strText + " from " + strInputLang + " to " + strOutputLang);
					try {
						strTranslation = this.googleTranslate(strText, strInputLang, strOutputLang);
					} catch(GLib.Error objError){
						Logger.Log(objError.message);
						this.sendMessage(strFrom, objError.message);
						break;
					}
					this.sendMessage(strFrom, strTranslation);
				break;
				case "URBAN":
					string strUrl = "http://www.urbandictionary.com/define.php?term=" + this.buildString(arrData, 1, true).replace(" ", "+");
					string strPage = Utils.fetch(strUrl);
					string strDefinition = Utils.getBetween(strPage, "<meta content='", "'");
					this.sendMessage(strFrom, strDefinition + (strDefinition.index_of("...") > -1 ? strUrl : ""));
				break;
			}
			this.lastCommandChannel = strFrom;
		}
		
		public void run(){
			this.netConnect(this.Config["Address"], this.Config["Port"]);
			while(true){
				if(this.Connection.is_closed() == true){
					break;
				}
				this.recvData();
			}
		}
		
	}
	
}
