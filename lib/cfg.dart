library cfg;

import 'package:google_games_v1_api/games_v1_api_browser.dart' as gamesclient;

const API_KEY_BROWSER = "AIzaSyBjjQFMby5YFoYret4-LOkYAN48yRBoJOw";
const OAUTH2_CLIENT_ID = "3931543537.apps.googleusercontent.com";
const GAME_APP_ID = "3931543537";
const SERVICE_ACCOUNT_ID = "3931543537@developer.gserviceaccount.com";
var DATA_SCOPES = [gamesclient.Games.GAMES_SCOPE, "email", "openid"]; //, "email"];