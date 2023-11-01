
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
	document.cookie = name + "=" + value + expires + "; path=/; " + "SameSite=None; Secure";
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

/* next two also in edit.js.  Need to clean up */
Storage.prototype.setObject = function(key, value) {
//    this.setItem(key, JSON.stringify(value));
    this.setItem(key, JSON.stringify(value, function(key, val) {
//    console.log("key", key, "value", value, "val", val);
    return val.toFixed ? Number(val.toFixed(3)) : val;
}));
}

Storage.prototype.getObject = function(key) {
    var value = this.getItem(key);
    return value && JSON.parse(value);
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
    the_form += '<button type="submit">Yes, really logout</button>';
    the_form += '<div id="dontlogout" class=dontlogout">Stay logged in</div>'
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

function survey_form(surveylink) {
    var the_form = "";

/*    the_form += '<div id="theloginform" class="modal login">';
*/
    the_form += '<div class="modal-content">';
    the_form += '<p class="instructions">Can you take a brief survey<br>about your use of this book?</p>';
    the_form += '<button class="surveyresponse" id="takesurvey">Yes, I can take the survey<br>(opens new window)</button>';
    the_form += '<button class="surveyresponse" id="remindlater">Not now.  Please remind me later.</button>';
    the_form += '</div>\n';
  
  theform = document.createElement('div');
  theform.id = "the" + "survey" + "form";
  theform.className = "modal survey";
  document.body.appendChild(theform);
  theform.innerHTML = the_form;
}


function loadScript(script) {
  if (typeof js_version === 'undefined') { js_version = '0.12' }
  var newscript = document.createElement('script');
  newscript.type = 'text/javascript';
  newscript.async = true;
  newscript.src = 'https://pretextbook.org/js/' + js_version + '/' + script + '.js';
  var allscripts = document.getElementsByTagName('script');
  var s = allscripts[allscripts.length - 1];
  console.log('s',s);
  console.log("adding a script", newscript);
  s.parentNode.insertBefore(newscript, s.nextSibling);
}


function removeLogin() {
    eraseCookie("ut_cookie");
}

var uname = "";
var emanu = "";

function check_role() {
    console.log("check_role for", uname, "uname");
    if(uname=="instructor") { return "instructor" }
    var_role_data = {"action": "check", "user": uname, "pw": emanu, "type": "instructor", "instId": uname}
    var role_key = "";
    $.ajax({
      url: "https://aimath.org/cgi-bin/u/highlights.py",
      type: "post",
      data: JSON.stringify(var_role_data),
      dataType: "json",
      async: false,
      success: function(data) {
          console.log("something", data, "back from highlight");
          role_key = data
      },
      error: function(errMsg) {
        console.log("seems to be an error?",errMsg);
//        alert("Error X2\n" + errMsg);
      }
    });

  console.log("done checking role", role_key);
  return role_key
}

function validateLogin() {
    var logged_in = false;
    var un = document.loginform.uname.value;
//    un = un.toLowerCase();
    uname = un;
    var pw = document.loginform.psw.value;
    emanu = pw;
    console.log("xuname", uname, "yemanu", emanu);
    var guest_name = "guest";
    var the_password_guest = "guest";
    var editor_name = "editor";
    var the_password_editor = "editor";
    var instructor_name = "instructor";
    var the_password_instructor = "instructor";
    var the_un_enc = hash_of_string(un);
    console.log("un", un, "the_un_enc", "y"+the_un_enc+"y", "pw", "x"+pw+"x", "pw == the_un_enc", pw == the_un_enc);
    var the_url_enc = hash_of_string(window.location.hostname);
    console.log('window.location.hostname ' + window.location.hostname);
    if ((typeof guest_access !== 'undefined') && guest_access && ( ((un == guest_name) && (pw == the_password_guest))  || ((un == editor_name) && (pw == the_password_editor))) ) {
        console.log("setting the guest ut_cookie");
        createCookie('ut_cookie',un,0.25);
        logged_in = true;
        console.log("logged in as guest", logged_in);
    }
    else if ((typeof guest_access !== 'undefined') && guest_access && (un == instructor_name) && (pw == the_password_instructor)) {
        console.log("setting the instructor ut_cookie");
        createCookie('ut_cookie',un,0.25);
        logged_in = true;
        console.log("logged in as instructor", logged_in);
        role = "instructor";
    }
    else if (pw == the_un_enc) {
        console.log("setting the ut_cookie");
        createCookie('ut_cookie',un,150);
        logged_in = true;
    }
    else if (pw == the_url_enc) {
        console.log("setting the url ut_cookie");
        createCookie('ut_cookie',un,0.25);
        logged_in = true;
    }
    else {
   //     alert ('Login was unsuccessful, please check id: "' + uname + '" and password"' + emanu +'".  Also checking "' + pw + '" and "' + the_un_enc + '".');
        alert ('Login was unsuccessful, please check id: "' + uname + '".');
        console.log("failed to set the ut_cookie");
        logged_in = false;
    }
    console.log("logged_in", logged_in);
    if (logged_in) {
        $("#theloginform").hide();
        document.getElementById('loginlogout').innerHTML = 'logout' + ' ' + un;
        if(uname != "editor") {
            loadScript('answer');
            loadScript('highlight')
            if ((typeof trails !== 'undefined') && trails) {
                loadScript('trails');
            }
        }
    }
    var role_key = check_role();
    console.log("role_key", role_key);
    if (role_key) {
        console.log("another instructor", role_key);
        role = 'instructor'
    }
//    if (logged_in && /^\d+$/.test(uname) && ( (uname.length == 5 || uname.length == 8 && /^\d+00$/.test(uname)) )) {
//        console.log("an instructor");
//        role = 'instructor'
//    }

    console.log("role", role);
    return logged_in
  }

var aa_id = readCookie('aa_cookie');

if (aa_id) {
    console.log("found cookie");
    console.log(aa_id);
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
    aa_id = date_str_trimmed;
    createCookie('aa_cookie',aa_id,150);
}

/* dataurlbase = dataurlbase.concat("per").concat("=").concat(aa_id).concat("&");
*/

var ut_id = readCookie('ut_cookie');
uname = ut_id || "";

if(uname == "instructor") { role="instructor"}

console.log("uname", uname);


var pageIdentifier = "";

window.addEventListener('load', function(){
    console.log("checking login", ut_id);
bodyID = document.getElementsByTagName('body')[0].id;
console.log("bodyID", bodyID);
if (bodyID) {
    var secID = document.getElementsByTagName('section')[0].id;
    if (secID) {
        pageIdentifier = bodyID + "___" + secID
    }
}

if (pageIdentifier) {

  if (ut_id) {
    console.log("found "+ut_id);
    $("#theloginform").hide();

 //   if (/^\d+$/.test(uname) && ( (uname.length == 5 || uname.length == 8 && /^\d+00$/.test(uname)) )) {
    var role_key = check_role();
    console.log("the role_key", role_key);
    if (role_key) {
        console.log("another instructor", role_key);
        role = 'instructor'
    }
    document.getElementById('loginlogout').className = 'logout';
    document.getElementById('loginlogout').innerHTML = 'logout' + ' ' + ut_id;
    console.log("done hiding "+ut_id);
    loadScript('answer');
    if(uname != "editor") {loadScript('highlight')}
    if ((typeof trails !== 'undefined') && trails) {
            loadScript('trails');
    }
  }
  else if (typeof login_required !== 'undefined' && login_required) {
    login_form();
  }

  $("#loginlogout.logout").click(function(){
     login_form('logout');
     $("#dontlogout").click(function() {
         $("#thelogoutform").remove()
     });
  });
  $("#loginlogout.login").click(function(){
     login_form('login');
  });
} else {
    console.log("login not enabled because document not identified")
}
 //   console.log("the role", role);
});

