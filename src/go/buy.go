package api

import (
	"errors"
	"fmt"
	"time"
	//	"code.google.com/p/goauth2/oauth/jwt"
	"appengine"
	"encoding/json"
	"github.com/dgrijalva/jwt-go"
	"net/http"
	"strconv"
)

func init() {
	http.HandleFunc("/api/demo/buy", buyDemo)
	http.HandleFunc("/api/buy_bill", buyBill)
	http.HandleFunc("/api/buy_postback", buyPostBack)
}

func buyDemo(w http.ResponseWriter, req *http.Request) {
	w.Header().Set("Content-Type", "text/html")
	fmt.Fprintf(w, x)
}

type AmountReq struct {
	Amount string `json:"amount"`
	Jwt    string `json:"jwt"`
}

type ReplyError struct {
	Error string `json:"error"`
}

func returnJsonError(w http.ResponseWriter, msg string, c appengine.Context) {
	c.Warningf(msg)
	t := ReplyError{
		Error: msg,
	}
	//http.Error(w, msg, http.StatusBadRequest)
	w.WriteHeader(http.StatusBadRequest)
	json.NewEncoder(w).Encode(&t)
}
func buyBill(w http.ResponseWriter, req *http.Request) {
	c := appengine.NewContext(req)
	decoder := json.NewDecoder(req.Body)
	var t AmountReq
	err := decoder.Decode(&t)
	if err != nil {
		returnJsonError(w, "can't decode the request", c)
		return
	}
	amount, err := strconv.ParseFloat(t.Amount, 64)
	if err != nil {
		returnJsonError(w, "can't parse the amount", c)
		return
	}
	if amount < 1.0 {
		returnJsonError(w, "no enough amount", c)
		return
	}
	t.Amount = strconv.FormatFloat(amount, 'f', 2, 64)
	t.Jwt = makeToken(amount)
	json.NewEncoder(w).Encode(&t)
}

//TODO log success and failure (in log file of Google Analytics)
func buyPostBack(w http.ResponseWriter, req *http.Request) {
	token, err := jwt.Parse(req.FormValue("jwt"), func(token *jwt.Token) ([]byte, error) {
		return sellerSecret, nil
	})

	if err != nil || !token.Valid {
		w.WriteHeader(http.StatusNotAcceptable)
		return
	}
	orderId, _, _, err := extractPostBack(token.Claims)
	if err != nil {
		w.WriteHeader(http.StatusNotAcceptable)
		return
	}
	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, orderId)
}

func extractPostBack(claims map[string]interface{}) (string, string, string, error) {
	if claims["iss"] != paymentId {
		return "", "", "", errors.New("'iss' is invalid")
	}
	if claims["aud"] != sellerId {
		return "", "", "", errors.New("'aud' is invalid")
	}
	if claims["typ"] != "google/payments/inapp/item/v1/postback/buy" {
		return "", "", "", errors.New("'typ' is invalid")
	}
	//TODO check exp and iat
	//TODO extract sellerData
	response := claims["response"].(map[string]interface{})
	orderId := response["orderId"].(string)
	request := claims["request"].(map[string]interface{})
	amount := request["price"].(string)
	currency := request["currencyCode"].(string)
	return orderId, amount, currency, nil
}

// to test https://sandbox.google.com/checkout/inapp/merchant/demo.html
func makeToken(amount float64) string {
	signer := jwt.GetSigningMethod("HS256")
	token := jwt.New(signer)
	data := map[string]string{
		"name":         "Piece of Cake",
		"description":  "Virtual chocolate cake to fill your virtual tummy",
		"price":        fmt.Sprintf("%.2f", amount),
		"currencyCode": "EUR",
		"sellerData":   "user_id:1224245,offer_code:3098576987,affiliate:aksdfbovu9j",
	}
	now := time.Now().Unix()
	//now = 1382977357
	token.Claims["iss"] = sellerId
	token.Claims["aud"] = paymentId
	token.Claims["typ"] = "google/payments/inapp/item/v1"
	token.Claims["iat"] = now
	token.Claims["exp"] = now + 3600
	token.Claims["request"] = data

	tokenString, _ := token.SignedString(sellerSecret)
	return tokenString
}

const x = `
<script src="https://sandbox.google.com/checkout/inapp/lib/buy.js"></script><script type="text/javascript">
function askJwt() {
	var http = new XMLHttpRequest();
	var url = "/api/buy_bill";
	var params = {
		"amount" : amount()
	};
	http.open("POST", url, true);

	//Send the proper header information along with the request
	http.setRequestHeader("Content-type", 'application/json; charset=utf-8');
	//http.setRequestHeader("Content-length", params.length);
	//http.setRequestHeader("Connection", "close");

	http.onreadystatechange = function() {//Call a function when the state changes.
		if(http.readyState == 4 && http.status == 200) {
			var info = JSON.parse(http.responseText);
			console.log(info)
			if (info.amount == amount()) {
				google.payments.inapp.buy({
					parameters: {},
					jwt: info.jwt,
					success: function() {window.alert("success")},
					failure: function() {window.alert("failure")}
				});
			}
		}
	}
	http.send(JSON.stringify(params));
}
function amount(){
	//TODO check is a number (float32)
	//TODO check is min 1.00 EUR
	return document.getElementById("amount").value;
}
function setup() {
	runDemoButton = document.getElementById("runDemoButton");
	runDemoButton.onclick = function() {
		askJwt();
		return false;
	};
}
</script>
<!--- place button in the appropriate place on your page-->
<body onload="setup()">
  <input id="amount" type="text" value="1.00"/> EURO
  <button id="runDemoButton" value="buy"><b>Purchase</b></button>
</body>
`
