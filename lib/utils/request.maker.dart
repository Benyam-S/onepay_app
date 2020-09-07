import 'package:flutter/material.dart';

class HttpRequester {
  String baseURI = "http://192.168.1.7:8080/api/v1";
  String requestURL = "";

  HttpRequester({@required String path}){
    if (path.startsWith("/")){
      requestURL = Uri.encodeFull( baseURI + path);
    }else{
      requestURL = Uri.encodeFull(baseURI + "/"+ path);
    }
  }
}