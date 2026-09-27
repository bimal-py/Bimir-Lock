import 'dart:convert';
import 'dart:developer';

import 'package:bimir_lock/models/quote_model.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class QuotesRemoteDatasource {
  //take requesto handler from const param
  // QuotesRemoteDatasource();
  Future<List<Quote>?> getQuotes(
      {String? category = "success", int limit = 3}) async {
    var headers = {
      'X-Api-Key': 'F5sdBIU08xRDwzeww7nLFVpm3MxMUFW7q0c3tOJw',
    };
    var url = Uri.parse(
        // "https://api.api-ninjas.com/v1/quotes?category=$category&limit=$limit");
        "https://api.api-ninjas.com/v1/quotes?category=$category");
    // var contentType = 'application/json';
    try {
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        var quotesList = quotesfromJson(jsonDecode(response.body));
        return quotesList;
      } else {
        var responseMessage = jsonDecode(response.body);
        if (responseMessage is Map && responseMessage.containsKey("error")) {
          Fluttertoast.showToast(msg: responseMessage["error"],
              backgroundColor: Colors.black, textColor: Colors.white);
        } else {
          Fluttertoast.showToast(
              msg: "Something went wrong when fetching quotes data",
              backgroundColor: Colors.black, textColor: Colors.white);
        }
      }
    } catch (e) {
      log("==============>>>>> Error while fetching quotes: $e");
      return null;
    }
    return null;
  }
}
