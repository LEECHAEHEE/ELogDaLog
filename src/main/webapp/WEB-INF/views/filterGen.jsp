<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<!DOCTYPE html>
<head>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css">
<style>
.bucket {
    height: 30px;
    border: 1px solid #aaaaaa;
}
.item {
    padding: 10px;
    border: 1px solid #aaaaaa;
}
</style>
</head>

<body>

<div class="container theme-showcase" role="main">
<div class="jumbotron">
	<h1>Logstash Filter Generator</h1>
	<p>파일명, 로그데이터 </p>
</div>
<div class="panel panel-primary">
	<div class="panel-heading">파일명, 로그데이터를 구분자로 분할</div>
	<div class="panel-body">
		<form id="frm" action="/filterGen">
			<div class="form-group col-md-6">
		  		<label>로그 파일명</label>
		  		<input type="text" id="filename" class="form-control" value="devweb_devweb.dcsms.co.kr_access_18081615.log">
		  	</div>
			<div class="form-group col-md-6">
		  		<label>파일명 구분자</label>
		  		<input type="text" id="filenameSep" class="form-control" value="[\-\_\^\.\s\[\]\|\:]+">
		  	</div>
			<div class="form-group col-md-6">
		  		<label>로그 데이터</label>
		  		<input type="text" id="logdata" class="form-control" value="[2018-08-16 15:57:51] jwmoon|172.21.25.207|/synergy/content/callerbook/limit_list">
		  	</div>
			<div class="form-group col-md-6">
		  		<label>로그 데이터 구분자</label>
		  		<input type="text" id="logdataSep" class="form-control" value="[\^\s\[\]\|]+">
		  	</div>
		  	<button id="regSplitBtn" class="btn btn-primary" type="button" onclick="inputIsEmpty()">텍스트 분할</button>
		</form> 
	</div>
</div>

<div class="panel panel-primary">
	<div class="panel-heading">분할된 항목들 > 필드 데이터 (drag & drop)</div>
	<div class="panel-body">
	<div ondrop="drop(event)" ondragover="allowDrop(event)">
		<div id="filenameItems" style="height:50px"></div>
		<div id="logdataItems" style="height:50px"></div>
	</div>
	</div>
</div>

<div class="panel panel-primary">
	<div class="panel-heading">필드 데이터, 필드명과 매핑하여 필터 자동 생성</div>
	<div class="panel-body">
		<table class="table table-bordered table-striped table-hover">
		  <thead>
		    <tr>
		      <th scope="col" width="60%">필드 데이터</th>
		      <th scope="col">항목</th>
		      <th scope="col">필드</th>
		    </tr>
		  </thead>
		  <tbody>
		    <tr>
		      <th scope="row">
				<div id="server" class="bucket" ondrop="drop(event)" ondragover="allowDrop(event)"></div>
			  </th>
		      <td>서버 명</td>
		      <td>server</td>
		    </tr>
		    <tr>
		      <th scope="row">
				<div id="service" class="bucket" ondrop="drop(event)" ondragover="allowDrop(event)"></div>
			  </th>
		      <td>서비스 명</td>
		      <td>service</td>
		    </tr>
		    <tr>
		      <th scope="row">
				<div id="accessDate" class="bucket" ondrop="drop(event)" ondragover="allowDrop(event)"></div>
			  </th>
		      <td>접근 일시</td>
		      <td>access_date</td>
		    </tr>
		    <tr>
		      <th scope="row">
				<div id="accessIp" class="bucket" ondrop="drop(event)" ondragover="allowDrop(event)"></div>
			  </th>
		      <td>접근 IP</td>
		      <td>access_ip</td>
		    </tr>
		    <tr>
		      <th scope="row">
				<div id="accessId" class="bucket" ondrop="drop(event)" ondragover="allowDrop(event)"></div>
			  </th>
		      <td>접근 ID</td>
		      <td>access_id</td>
		    </tr>
		    <tr>
		      <th scope="row">
				<div id="accessUri" class="bucket" ondrop="drop(event)" ondragover="allowDrop(event)"></div>
			  </th>
		      <td>URI</td>
		      <td>access_uri</td>
		    </tr>
		    <tr>
		      <th scope="row">
				<div id="action" class="bucket" ondrop="drop(event)" ondragover="allowDrop(event)"></div>
			  </th>
		      <td>동작</td>
		      <td>action</td>
		    </tr>
		    <tr>
		      <th scope="row">
				<div id="remark" class="bucket" ondrop="drop(event)" ondragover="allowDrop(event)"></div>
			  </th>
		      <td>상세정보</td>
		      <td>remark</td>
		    </tr>
		  </tbody>
		</table>
		<button id="makeFilterBtn" class="btn btn-primary" type="button" onclick="makeFilter()">필터 생성</button>

	</div>
</div>
</div>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
<script>

/*
grok-patterns:
	noSep [^\-\_\^\.\s\[\]\|\:]+
	Sep [\-\_\^\.\s\[\]\|\:]+

filter example:
	%{Sep}?%{noSep:server}%{Sep}%{noSep}%{Sep}%{noSep}%{Sep}%{noSep:service}%{Sep}%{noSep}%{Sep}%{noSep}%{Sep}%{noSep:day1}%{Sep}%{noSep:filetype}$
*/

//구분자 정규식
var regSep;
var regSepR;
//var regIP = /((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[0-9]{1,2})\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[0-9]{1,2})/g;

//필드명, 필드데이터
var fieldName = ["server","service","accessDate","accessIp","accessId","accessUri","action","remark"];
var fieldDatas = {};

//ajax로 보낼 데이터
var jsonData = {};

/*
//extract seperator, 구분자 정보를 순서대로 추출하여, 필터를 생성할 때 사용한다.
function extSep(inputId, inputStr, inputItems){
	var Items;
	if(inputId == "filename")
		Items = inputStr.split(regSepFR);
	else
		Items = inputStr.split(regSepLR);
	
	var result = "";
	for (item in Items){
		//console.log(inputId+" item["+item+"] : "+Items[item]+", "+inputItems[item]);
		result += Items[item]+inputItems[item];
	}
	//console.log("result : "+result);
}
*/

function regSepUpdate(inputId){
	reg = document.getElementById(inputId+"Sep").value;
	regSep = new RegExp(reg);
	regSepR = new RegExp(reg.replace("/[","/[^"));
}

//구분자에 따라 입력받은 파일명과 로그데이터를 나눈다.
function splitInputSep(inputId){
	//입력한 파일명, 로그데이터
	var inputStr = document.getElementById(inputId).value;
	
	//구분자 수정
	regSepUpdate(inputId);
	var inputItems = inputStr.split(regSep);
		
	//구분자로 시작하는 경우, 공란이 생긴다. 제거
	if(inputItems[0]=="")
		inputItems.shift();
	
	//드래그할 item 생성
	for (item in inputItems){
	    var txt = "<span id=\""+inputId+"Item"+item+"\" class=\"item\" draggable=\"true\" ondragstart=\"drag(event)\">"+inputItems[item]+"</span>";
	    document.getElementById(inputId+"Items").innerHTML += txt;
	}
	/* 	
	//추후에 필드 데이터들이 IP인지 판별하는 작업 등에 쓰일 듯(구분자와 데이터를 사용하여)
	if(inputItems.length > 1)
		var inputSep = extSep(inputId, inputStr, inputItems);
	*/
}

//텍스트 분할 클릭 시 실행
function inputIsEmpty(){
	var filenameStr = document.getElementById("filename").value;
	var logdataStr = document.getElementById("logdata").value;
	
 	//Items > span init
	document.getElementById("filenameItems").innerHTML = "";
	document.getElementById("logdataItems").innerHTML = "";
	
	//bucket > span init
	var divBuckets = document.getElementsByClassName("bucket");
	for (bucket in divBuckets)
		divBuckets[bucket].innerHTML="";
	
	if(filenameStr.length > 0)
		splitInputSep("filename");
	if(logdataStr.length > 0)
		splitInputSep("logdata");
}

//필드 데이터가 한 개인 경우
function singleFd(){
	var fdInfo = fieldDatas[fn][0];
	if(typeof fdInfo != "undefined"){
		jsonData[fieldName[fn]] = fdInfo.id;
	}	
}

//필드 데이터가 여러개인 경우(Object, String)
function multipleFd(fn){
	var jsonList = "";
	for (fd in fieldDatas[fn]){
		var fdInfo = fieldDatas[fn][fd].id;
		if(typeof fdInfo != "undefined"){
			jsonList += fdInfo+",";
		}
	}
	if(jsonList != "")
		jsonData[fieldName[fn]] = jsonList.slice(0,-1);
}


//필터 생성 시 실행
function makeFilter(){
	//각 필드마다 드랍된 필드 데이터에 대한 정보를 읽는다. (필터 생성에 필요함)
	//필드 데이터들의 태그 id를 읽어,
	//각 데이터들이 어떤 문자열인지와 순서, 어떤 필드를 나타내는지 알아낸다.
	for (fn in fieldName){
		fieldDatas[fn] = document.getElementById(fieldName[fn]).children;
		
	 	//if(fieldName[fn] == "accessDate" || fieldName[fn] == "accessIp" || fieldName[fn] == "accessUri")
	 		multipleFd(fn);
	 	//else 
	 	//	singleFd();
	}
	//send json
	jsonAjax();
}

function jsonAjax(){

/* 	jsonData = 
		{
		  "server": "filenameItem0",
		  "service": "filenameItem3",
		  "accessDate": "filenameItem6,logdataItem3,logdataItem4",
		  "accessIp": "logdataItem5,logdataItem6,logdataItem7,logdataItem8",
		  "accessId": "logdataItem1",
		  "accessUri": "logdataItem9,logdataItem10",
		  "action": "logdataItem11",
		  "remark": "logdataItem12"
		}
 */	
	$.ajax({
	    url:"filterGenForm",
	    type:'POST',
// 	  	dataType:'json',
	    data:jsonData,
	    success:function(res){
	    	alert(res);
	    },
	    error:function(err){
	        alert("err: "+err);
	    }
	});
}

function allowDrop(ev) {
    ev.preventDefault();
}

function drag(ev) {
    ev.dataTransfer.setData("text", ev.target.id);
}

function drop(ev) {
    ev.preventDefault();
    var data = ev.dataTransfer.getData("text");
    ev.target.appendChild(document.getElementById(data));
}

/*
//필드 데이터가 여러개인 경우(List Object)
function multipleFd2(fn){
	var fList = {};
	var lList = {};
	var jsonList = [];
	//jsonList.keys("filename","logdata");
	for (fd in fieldDatas[fn]){
		var fdInfo = fieldDatas[fn][fd].id;
		if(typeof fdInfo != "undefined"){
			//filenameItem3 >> filenameItem , 3 split
			var fdInfoDoc = fdInfo.replace(/[0-9]+/g,"");
			var fdInfoSeq = fdInfo.replace(/[^0-9]+/g,"");
			if(fdInfoDoc == "filenameItem"){
				fList[fdInfoDoc] = fdInfoSeq;
				jsonList.push(fList);
			}
			else{
				lList[fdInfoDoc] = fdInfoSeq;
				jsonList.push(lList);
				
			}
		}
	}
	jsonData[fieldName[fn]] = jsonList;
	console.log(jsonData);
}
//결과물
	jsonData =
		{
		  "server": [
		    {
		      "filenameItem": "0"
		    }
		  ],
		  "service": [
		    {
		      "filenameItem": "3"
		    }
		  ],
		  "accessDate": [
		    {
		      "filenameItem": "6"
		    },
		    {
		      "logdataItem": "4"
		    }
		  ],
		  "accessIp": [
		    {
		      "logdataItem": "8"
		    },
		    {
		      "logdataItem": "8"
		    },
		    {
		      "logdataItem": "8"
		    },
		    {
		      "logdataItem": "8"
		    }
		  ],
		  "accessId": [
		    {
		      "logdataItem": "1"
		    }
		  ],
		  "accessUri": [
		    {
		      "logdataItem": "10"
		    },
		    {
		      "logdataItem": "10"
		    }
		  ],
		  "action": [
		    {
		      "logdataItem": "11"
		    }
		  ],
		  "remark": [
		    {
		      "logdataItem": "12"
		    }
		  ]
		}
*/

/*
//필드 데이터가 여러개인 경우 (Object : List)
function multipleFd1(fn){
	var fList = [];
	var lList = [];
	var jsonList = {};
	//jsonList.keys("filename","logdata");
	for (fd in fieldDatas[fn]){
		var fdInfo = fieldDatas[fn][fd].id;
		if(typeof fdInfo != "undefined"){
			//filenameItem3 >> filenameItem , 3 split
			var fdInfoDoc = fdInfo.replace(/[0-9]+/g,"");
			var fdInfoSeq = fdInfo.replace(/[^0-9]+/g,"");
			
			if(fdInfoDoc == "filenameItem"){
				fList.push(fdInfoSeq);
				jsonList[fdInfoDoc] = fList;
			}
			else{
				lList.push(fdInfoSeq);
				jsonList[fdInfoDoc] = lList;
			}
		}
	}
	jsonData[fieldName[fn]] = jsonList;
} 

//결과물
	jsonData =
		{
			"server": {
				"filenameItem": ["0"]
			},
			"service": {
				"filenameItem": ["3"]
			},
			"accessDate": {
				"filenameItem": ["6"],
				"logdataItem": ["3", "4"]
			},
			"accessIp": {
				"logdataItem": ["5", "6", "7", "8"]
			},
			"accessId": {
				"logdataItem": ["1"]
			},
			"accessUri": {
				"logdataItem": ["9", "10"]
			},
			"action": {
				"logdataItem": ["11"]
			},
			"remark": {}
		}

*/

/*
//구분자에 따라 입력받은 파일명과 로그데이터를 나눈다.
function splitInputSep(){
	//입력한 파일명, 로그데이터
	var filename_str = document.getElementById("filename").value;
	var logdata_str = document.getElementById("logdata").value;

	//구분자에 따라 분할
	var filename_items = filename_str.split(reg);
	//Items > span 초기화
	document.getElementById("filenameItems").innerHTML = "";
	//드래그할 item 생성
	for (item in filename_items){
	    var txt = "<span id=\"filenameItem"+item+"\" class=\"item\" draggable=\"true\" ondragstart=\"drag(event)\">"+filename_items[item]+"</span>";
	    document.getElementById("filenameItems").innerHTML += txt;
	}

	//구분자에 따라 분할
	var logdata_items = logdata_str.split(reg)
	//Items > span 초기화
	document.getElementById("logdataItems").innerHTML = "";
	for (item in logdata_items){
	    var txt = "<span id=\"logdataItem"+item+"\" class=\"item\" draggable=\"true\" ondragstart=\"drag(event)\">"+logdata_items[item]+"</span>";
	    document.getElementById("logdataItems").innerHTML += txt;
	}
	
	//extract seperator
	extSep();
	
}

//구분자 정보를 순서대로 추출하여, 필터를 생성할 때 사용한다.
function extSep(){
	
}

function makeFilter(){
	console.log($("#server > span").text());
	
	
	$("#filterGenForm").submit();
}
*/
</script>
</body>
</html>
