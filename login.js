
console.log("enabling login");

function createCookie(name,value,days) {
	if (days) {
		var date = new Date();
		date.setTime(date.getTime()+(days*24*60*60*1000));
		var expires = "; expires="+date.toGMTString();
	}
	else var expires = "";
/*	document.cookie = name+"="+value+expires+"; path=/; domain=aimath.org";
*/
	document.cookie = name+"="+value+expires+"; path=/";
        console.log("created cookie " + name);
}

function readCookie(name) {
	var nameEQ = name + "=";
	var ca = document.cookie.split(';');
	for(var i=0;i < ca.length;i++) {
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1,c.length);
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
	}
	return null;
}

function eraseCookie(name) {
	createCookie(name,"",-1);
}

function hash_of_string(str) {
    str = str.toString();
    var the_len = str.length;
    the_len = Math.min(12,the_len);
    var the_hash = 123456;
    var hash_lis = [510149, 120151, 230157, 411063, 320167, 631973, 410179, 321081, 231091, 111093, 121097, 230199];
    for (var j=0; j < the_len; ++ j) {
        var this_char = str.charCodeAt(j);
        this_char = parseInt(this_char);
        var this_add = this_char * hash_lis[j];
        the_hash += this_add;
        the_hash = the_hash % 1000000;
    }
    return the_hash.toString()
}

function login_form(mode="login") {
    var the_form = "";

/*    the_form += '<div id="theloginform" class="modal login">';
*/
  if (mode == 'logout') {
    the_form += '<form name="logoutform" class="modal-content animate" onSubmit="return removeLogin();" action="">';
    the_form += '<div class="container">\n';
    the_form += '<button type="submit">Really logout</button>';
    the_form += '</div>\n';
    the_form += '</form>\n';
  }
  else{
    the_form += '<form name="loginform" class="modal-content animate" onSubmit="return validateLogin();" action="">';
    if ((typeof guest_access !== 'undefined') && guest_access) {
        the_form += '<p class="instructions" >You can log in as "guest" with password "guest" for 3 hours of access.</p>'; }
    the_form += '<div class="container">\n';
    the_form += '<label><b>Id</b></label>\n<input type="text" placeholder="Enter Username" name="uname" required>';
    the_form += '<label><b>Password</b></label>\n<input type="password" placeholder="Enter Password" name="psw" required>';
    the_form += '<button type="submit">Login</button>';
    the_form += '</div>\n';
    the_form += '<div class="container" style="background-color:#f1f1f1">';
    the_form += '<span class="psw">Login trouble? Email <a href="mailto:help@aimath.org">help@aimath.org</a></span>';
    the_form += '</div>\n';
    the_form += '</form>\n';
  }

  theform = document.createElement('div');
  theform.id = "the" + mode + "form";
  theform.className = "modal login";
  document.body.appendChild(theform);
  theform.innerHTML = the_form;
}

function loadScript(script) {
  var newscript = document.createElement('script');
  newscript.type = 'text/javascript';
  newscript.async = true;
  newscript.src = 'https://pretextbook.org/js/0.1/' + script + '.js';
  var allscripts = document.getElementsByTagName('script');
  var s = allscripts[allscripts.length - 1];
  console.log('s',s);
  s.parentNode.insertBefore(newscript, s);
}


function removeLogin() {
    eraseCookie("tr_cookie");
}

function validateLogin() {
    var logged_in = false;
    var un = document.loginform.uname.value;
    un = un.toLowerCase();
    var pw = document.loginform.psw.value;
    var guest_name = "guest";
    var the_password_guest = "guest";
    var the_un_enc = hash_of_string(un);
    var the_url_enc = hash_of_string(window.location.hostname);
    console.log("in validateLogin");
    console.log(un);
    console.log(pw);
    console.log('window.location.hostname ' + window.location.hostname);
    if ((typeof guest_access !== 'undefined') && guest_access && (un == guest_name) && (pw == the_password_guest)) {
        console.log("setting the guest tr_cookie");
        createCookie('tr_cookie',un,0.125);
        logged_in = true;
        console.log("logged in as guest", logged_in);
    }
    else if (pw == the_un_enc) {
        console.log("setting the tr_cookie");
        createCookie('tr_cookie',un,150);
        logged_in = true;
    }
    else if (pw == the_url_enc) {
        console.log("setting the tr_cookie");
        createCookie('tr_cookie',un,1);
        logged_in = true;
    }
    else {
        alert ("Login was unsuccessful, please check id and password");
        console.log("failed to set the tr_cookie");
        logged_in = false;
    }
    console.log("logged_in", logged_in);
    if (logged_in) {
        document.getElementById('loginlogout').innerHTML = 'logout';
        loadScript('answer');
    }
    return logged_in
  }

var this_id = readCookie('p_cookie');

if (this_id) {
    console.log("found cookie");
    console.log(this_id);
    var date = new Date();
    var date_now = date.getTime();
    var date_str = date_now.toString();
    var date_str_trimmed = date_str.slice(5,13);
    console.log(date_str)
    console.log(date_str_trimmed)
}
else {
    console.log("no cookie found")
    var date = new Date();
    var date_now = date.getTime();
    var date_str = date_now.toString();
    var date_str_trimmed = date_str.slice(5,13);
    this_id = date_str_trimmed;
    createCookie('p_cookie',this_id,150);
}

/* dataurlbase = dataurlbase.concat("per").concat("=").concat(this_id).concat("&");
*/

var a_id = readCookie('tr_cookie');

window.addEventListener('load', function(){
    console.log("checking login", a_id);
if (a_id) {
    console.log("found "+a_id);
    $("#theloginform").hide();

    console.log("repeating "+a_id);

/*    dataurlbase = dataurlbase.concat("tr_id").concat("=").concat(a_id).concat("&");
*/
    document.getElementById('loginlogout').className = 'logout';
    document.getElementById('loginlogout').innerHTML = 'logout';
    console.log("done hiding "+a_id);
    loadScript('answer');
}
else if (typeof login_required !== 'undefined' && login_required) {
    console.log("show the generated login form");
    login_form();
}

  $("#loginlogout.logout").click(function(){
     console.log("make the logout form");
     login_form('logout');
    });
  $("#loginlogout.login").click(function(){
     console.log("make the login form");
     login_form('login');
    });
});
