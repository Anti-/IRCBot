namespace IRCBot {
	
	class Bot : BotBase {
		
		private bool blnSinging;
		private bool blnStopSinging;
		
		public override void* handleCommand(string strFrom, string strMessage, string[] arrFull = {}){
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
					string strPage = Utils.fetch(this.Config["PHPFile"] + "?type=g&q=" + this.buildString(arrData, 1, true));
					string[] arrResults = strPage.split("\n");
					for(int intResult = 0; intResult < arrResults.length; intResult++){
						this.sendMessage(strFrom, arrResults[intResult]);
					}
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
				case "SHUTUP":
					if(this.blnSinging == false){
						this.sendMessage(strFrom, "There is no song being sung");
					} else {
						this.blnStopSinging = true;
					}
				break;
				case "SING":
					string strAPI = this.Config["MusixAPI"];
					string strArtist = arrData[1].replace(".", "%20").chomp();
					string strSong = arrData[2].replace(".", "%20").chomp();
					string strUrl = this.Config["PHPFile"] + "?type=mm&api=" + strAPI + "&artist=" + strArtist + "&song=" + strSong;
					string strPage = Utils.fetch(strUrl);
					Logger.Log(strUrl + " - " + strPage);
					string[] arrLyrics = strPage.split("\n");
					this.blnSinging = true;
					for(int intCount = 0; intCount < arrLyrics.length; intCount++){
						if(this.blnStopSinging == true){
							this.sendMessage(strFrom, "Stopping song");
							this.blnStopSinging = false;
							break;
						} else {
							this.sendMessage(strFrom, arrLyrics[intCount]);
							Posix.sleep(1);
						}
					}
					this.blnSinging = false;
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
					this.sendMessage(strFrom, strDefinition + (strDefinition.index_of("...") > -1 ? " " + strUrl : ""));
				break;
			}
			this.lastCommandChannel = strFrom;
			return null;
		}
		
		public void run(){
			this.netConnect(this.Config["Address"], this.Config["Port"]);
			for(;;){
				if(this.Connection.is_closed() == true){
					break;
				}
				this.recvData();
			}
		}
		
	}
	
}
