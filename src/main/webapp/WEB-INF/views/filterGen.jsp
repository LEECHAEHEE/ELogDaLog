<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>

<!DOCTYPE html>
<head>
<link rel="stylesheet"
	href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css">
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
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
			<p>파일명, 로그데이터</p>
		</div>
		<div class="panel panel-primary">
			<div class="panel-heading">파일명, 로그데이터를 구분자로 분할</div>
			<div class="panel-body">
				<form id="frm" action="/filterGen">
					<div class="form-group col-md-6">
						<label>로그 파일명</label> <input type="text" id="filename"
							class="form-control"
							value="devweb_devweb.dcsms.co.kr_access_18081615.log">
					</div>
					<div class="form-group col-md-6">
						<label>파일명 구분자</label> <input type="text" id="filenameSep"
							class="form-control" value="[\_\.\[\]]+">
					</div>
					<div class="form-group col-md-6">
						<label>로그 데이터</label> <input type="text" id="logdata"
							class="form-control"
							value="[2018-08-16 15:57:51] jwmoon|172.21.25.207|/synergy/content/callerbook/limit_list">
					</div>
					<div class="form-group col-md-6">
						<label>로그 데이터 구분자</label> <input type="text" id="logdataSep"
							class="form-control" value="[\^\s\[\]\|]+">
					</div>
					<button id="regSplitBtn" class="btn btn-primary" type="button"
						onclick="startFilterGen()">텍스트 분할</button>
				</form>
			</div>
		</div>

		<div class="panel panel-primary">
			<div class="panel-heading">분할된 항목들 > 필드 데이터 (drag & drop)</div>
			<div class="panel-body">
				<div ondrop="drop(event)" ondragover="allowDrop(event)">
					<div id="filenameItems" style="height: 50px"></div>
					<div id="logdataItems" style="height: 50px"></div>
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
								<div id="server" class="bucket" ondrop="drop(event)"
									ondragover="allowDrop(event)"></div>
							</th>
							<td>서버 명</td>
							<td>server</td>
						</tr>
						<tr>
							<th scope="row">
								<div id="service" class="bucket" ondrop="drop(event)"
									ondragover="allowDrop(event)"></div>
							</th>
							<td>서비스 명</td>
							<td>service</td>
						</tr>
						<tr>
							<th scope="row">
								<div id="file_date" class="bucket" ondrop="drop(event)"
									ondragover="allowDrop(event)"></div>
							</th>
							<td>파일 생성일시</td>
							<td>file_date</td>
						</tr>
						<tr>
							<th scope="row">
								<div id="access_day" class="bucket" ondrop="drop(event)"
									ondragover="allowDrop(event)"></div>
							</th>
							<td>접근 일/일시</td>
							<td>access_day</td>
						</tr>
						<tr>
							<th scope="row">
								<div id="access_time" class="bucket" ondrop="drop(event)"
									ondragover="allowDrop(event)"></div>
							</th>
							<td>접근 시간</td>
							<td>access_time</td>
						</tr>
						<tr>
							<th scope="row">
								<div id="access_ip" class="bucket" ondrop="drop(event)"
									ondragover="allowDrop(event)"></div>
							</th>
							<td>접근 IP</td>
							<td>access_ip</td>
						</tr>
						<tr>
							<th scope="row">
								<div id="access_id" class="bucket" ondrop="drop(event)"
									ondragover="allowDrop(event)"></div>
							</th>
							<td>접근 ID</td>
							<td>access_id</td>
						</tr>
						<tr>
							<th scope="row">
								<div id="access_uri" class="bucket" ondrop="drop(event)"
									ondragover="allowDrop(event)"></div>
							</th>
							<td>URI</td>
							<td>access_uri</td>
						</tr>
						<tr>
							<th scope="row">
								<div id="action" class="bucket" ondrop="drop(event)"
									ondragover="allowDrop(event)"></div>
							</th>
							<td>동작</td>
							<td>action</td>
						</tr>
						<tr>
							<th scope="row">
								<div id="remark" class="bucket" ondrop="drop(event)"
									ondragover="allowDrop(event)"></div>
							</th>
							<td>상세정보</td>
							<td>remark</td>
						</tr>
					</tbody>
				</table>
				<button id="makeFilterBtn" class="btn btn-primary" type="button"
					onclick="makeFilter()">필터 생성</button>

			</div>
		</div>
	</div>
<script>
/*
grok regex patterns example:
	noSep [^\-\_\^\.\s\[\]\|\:]+
	Sep [\-\_\^\.\s\[\]\|\:]+

filter example:
	%{Sep}?%{noSep:server}%{Sep}%{noSep}%{Sep}%{noSep}%{Sep}%{noSep:service}%{Sep}%{noSep}%{Sep}%{noSep}%{Sep}%{noSep:day1}%{Sep}%{noSep:filetype}$
*/

//구분자 정규식(regSepUpdate())
var regSep;
var regSepInv;
//var regIP = /((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[0-9]{1,2})\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[0-9]{1,2})/g;

//필드명, 필드데이터
var fieldName = ["server","service","file_date","access_day","access_time","access_ip","access_id","access_uri","action","remark"];
var fieldDatas = {};

// fd,ldStr이 담길 배열
var fnList = [];
var ldList = [];

var fnCount;
var ldCount;

//ajax로 보낼 데이터
var jsonData = {};

/*
//extract seperator, 구분자 정보를 순서대로 추출
function extSep(inputId, inputStr, inputItems){
	var Items;
	if(inputId == "filename")
		Items = inputStr.split(regSepFR);
	else
		Items = inputStr.split(regSepLR);
	
	var result = "";
	for (item in Items){
		result += Items[item]+inputItems[item];
	}
}
*/

function regSepUpdate(inputId){
	reg = document.getElementById(inputId+"Sep").value;
	regSep = new RegExp(reg);
	regSepInv = new RegExp(reg.replace("/[","/[^"));
}

function outputStrInitialize(){
	//로그 스태시에 들어갈 기본 형태(1Item, 1Str 필요)
	var fnStr = "%{fnSep}%{fnSepInv}";
	var ldStr = "%{ldSep}%{ldSepInv}";

	//init
	fnList = [];
	ldList = [];
	
	//생성된 Item 갯수
	for (var i=0; i<fnCount; i++)
		fnList.push(fnStr);
	for (var i=0; i<ldCount; i++)		
		ldList.push(ldStr);
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
	//추후에 필드 데이터들이 IP인지 판별하는 작업 등에 쓰일 예정(구분자와 데이터를 사용하여)
	if(inputItems.length > 1)
		var inputSep = extSep(inputId, inputStr, inputItems);
	*/
}

//텍스트 분할 클릭 시 실행
function startFilterGen(){
	//입력받은 파일명, 로그데이터 init
	var filenameStr = document.getElementById("filename").value;
	var logdataStr = document.getElementById("logdata").value;
	
 	//생성된 Items > span init
	document.getElementById("filenameItems").innerHTML = "";
	document.getElementById("logdataItems").innerHTML = "";
	
	//bucket > span init
	var divBuckets = document.getElementsByClassName("bucket");
	for (bucket in divBuckets)
		divBuckets[bucket].innerHTML="";
	
	//inputIsEmpty?
	if(filenameStr.length > 0)
		splitInputSep("filename");
	if(logdataStr.length > 0)
		splitInputSep("logdata");
	
	//itemsCount
	fnCount = document.getElementById("filenameItems").children.length;
	ldCount = document.getElementById("logdataItems").children.length;
	
	//필터에 추가될 문자열 init
	outputStrInitialize()
}


//필드 데이터가 한 개인 경우
function singleFd(){
	var fdInfo = fieldDatas[fn][0];
	if(typeof fdInfo != "undefined"){
		fdInfo = fieldDatas[fn][0].id;
		//fdInfo = filenameItem3 --(split)--> filenameItem , 3 
		var fdInfoDoc = fdInfo.slice(0,-1);//filenameItem
		var fdInfoSeq = fdInfo.charAt(fdInfo.length - 1);//3
		
		//이 부분은 server:word2, service:word2 와 같이 묶어둔 정보를 만들어 두고 사용하는 방식으로 변경해야함.
		if(fdInfoDoc == "filenameItem"){
			if(fieldName[fn] == "server")
				fnList[fdInfoSeq] = fnList[fdInfoSeq].replace("{fnSepInv}","{WORD2:"+fieldName[fn]+"}");
			else if(fieldName[fn] == "service")
				fnList[fdInfoSeq] = fnList[fdInfoSeq].replace("{fnSepInv}","{WORD2:"+fieldName[fn]+"}");
			else if(fieldName[fn] == "file_date")
				fnList[fdInfoSeq] = fnList[fdInfoSeq].replace("{fnSepInv}","{DATENUM1:"+fieldName[fn]+"}");
			else
				fnList[fdInfoSeq] = fnList[fdInfoSeq].replace("{fnSepInv}","{fnSepInv:"+fieldName[fn]+"}");		
		}
		else{
			if(fieldName[fn] == "access_ip")
				ldList[fdInfoSeq] = ldList[fdInfoSeq].replace("{ldSepInv}","{IPORHOST:"+fieldName[fn]+"}");
			else if(fieldName[fn] == "access_id")
				ldList[fdInfoSeq] = ldList[fdInfoSeq].replace("{ldSepInv}","{WORD2:"+fieldName[fn]+"}");
			else if(fieldName[fn] == "access_day")
				ldList[fdInfoSeq] = ldList[fdInfoSeq].replace("{ldSepInv}","{DATENUM2:"+fieldName[fn]+"}");
			else if(fieldName[fn] == "access_time")
				ldList[fdInfoSeq] = ldList[fdInfoSeq].replace("{ldSepInv}","{TIME:"+fieldName[fn]+"}");
			else
				ldList[fdInfoSeq] = ldList[fdInfoSeq].replace("{ldSepInv}","{ldSepInv:"+fieldName[fn]+"}");
		}
	}	
}

/*
//필드 데이터가 여러 개인 경우(주로, access_date)
function multipleFd(fn){
	for (fd in fieldDatas[fn]){
		var fdInfo = fieldDatas[fn][fd].id;
		if(typeof fdInfo != "undefined"){
			//fdInfo = filenameItem3 --(split)--> filenameItem , 3 
			var fdInfoDoc = fdInfo.slice(0,-1);//filenameItem
			var fdInfoSeq = fdInfo.charAt(fdInfo.length - 1);//3
			
			if(fdInfoDoc == "filenameItem"){
					fnList[fdInfoSeq] = fnList[fdInfoSeq].replace("{fnSepInv}","{fnSepInv:"+fieldName[fn]+"}");		
			}
			else{
				if(fieldName[fn] == "access_ip")
					ldList[fdInfoSeq] = ldList[fdInfoSeq].replace("{ldSepInv}","{IPORHOST:"+fieldName[fn]+"}");
				else
					ldList[fdInfoSeq] = ldList[fdInfoSeq].replace("{ldSepInv}","{ldSepInv:"+fieldName[fn]+"}");
			}
		}
	}
	//console.log("multipleFd:"+fieldName[fn]);
} 
*/
//필터 생성 시 실행
function makeFilter(){
	//각 필드마다 마우스로 drop한 필드 데이터에 대한 정보를 읽는다
	//필드 데이터들의 태그 id를 통해 데이터 종류(*infoDoc), 순서(*infoSeq), 필드(fieldName[fn])를 알아내 필터 생성에 사용되는 문자열(*StrOut)을 만든다.
	outputStrInitialize();
	for (fn in fieldName){
		fieldDatas[fn] = document.getElementById(fieldName[fn]).children;
		//console.log("fieldName[fn]: "+fieldName[fn]+"fieldDatas[fn].length: "+fieldDatas[fn].length);
		
		//if(fieldDatas[fn].length > 1)
		//	multipleFd(fn);
		//else
			singleFd(fn);
	}

	//맨 앞엔 구분자가 없을 수 있다.
	fnList[0] = fnList[0].replace("{fnSep}","{fnSep}?");
	ldList[0] = ldList[0].replace("{ldSep}","{ldSep}?");
	
	var fnStrOut = "%{WINPATH:file_path}\\\\"+fnList.toString().replace(/,/g,"");//+"$";
	var ldStrOut = ldList.toString().replace(/,/g,"");//+"$";
	console.log("filenameStringOutput");
	console.log(fnStrOut);
	console.log("logdataStringOutput");
	console.log(ldStrOut);
	//send json
	//jsonAjax();
}

function jsonAjax(){
	$.ajax({
	    url:"filterGenForm",
	    type:'POST',
	    data:jsonData,
	    success:function(res){
	    	alert(res);
	    },
	    error:function(err){
	        alert("err: "+err);
	    }
	});
}

//drag & drop
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
//필드 데이터가 여러개인 경우(Object, String)
function multipleFd2(fn){
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
// 결과물
jsonData = 
	{
	  "server": "filenameItem0",
	  "service": "filenameItem3",
	  "access_date": "filenameItem6,logdataItem3,logdataItem4",
	  "access_ip": "logdataItem5,logdataItem6,logdataItem7,logdataItem8",
	  "access_id": "logdataItem1",
	  "access_uri": "logdataItem9,logdataItem10",
	  "action": "logdataItem11",
	  "remark": "logdataItem12"
	}

*/

</script>
</body>
</html>
