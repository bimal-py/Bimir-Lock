import 'dart:developer';

import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/models/quote_category_model.dart';
import 'package:bimir_lock/models/quote_model.dart';
import 'package:bimir_lock/utils/helper/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../../repo/remoteRepo/quotes_remote_datasource.dart';
import '../../views/user/add_user_detail.dart';

class QuotesCategoryController extends GetxController {
  final List quoteItems = [
    "art",
    "beauty",
    "business",
    "communications",
    "computers",
    "dreams",
    "education",
    "failure",
    "fear",
    "fitness",
    "freedom",
    "friendship",
    "future",
    "happiness",
    "hope",
    "imagination",
    "inspirational",
    "intelligence",
    "knowledge",
    "leadership",
    "life",
    "love",
    "money",
    "morning",
    "success"
  ];
  RxList<String> selectedList = RxList();
  void categoryTap(String value) {
    if (selectedList.contains(value)) {
      selectedList.remove(value);
    } else {
      if (selectedList.length < 6) {
        selectedList.add(value);
      } else {
        Fluttertoast.showToast(msg: "You cannot select more than 6 categories",
            backgroundColor: Colors.black, textColor: Colors.white);
      }
    }
    update();
  }

  bool isSelected(String value) {
    if (selectedList.contains(value)) return true;
    return false;
  }

  Future<void> onGoTap() async {
    await saveQuoteCategory();
    // save the category
    if (selectedList.isEmpty) {
      Fluttertoast.showToast(msg: "Please select at least 1 quote category",
          backgroundColor: Colors.black, textColor: Colors.white);
      return;
    } else {
      navigatorKey.currentState!.pushNamed(AddUserDetailPage.routeName);
    }
  }

  Future<void> saveQuoteCategory() async {
    DataBaseHelper databaseHelper = DataBaseHelper();
    await databaseHelper.deleteAllQuoteCategory();
    try {
      for (var quoteCategory in selectedList) {
        QuoteCategory category = QuoteCategory(quoteCategory: quoteCategory);
        await databaseHelper.insertQuoteCategory(category);
      }
    } catch (e) {
      log("================>> Error while saving quote category: $e");
    }
  }

  Future<void> loadQuotes() async {
    DataBaseHelper databaseHelper = DataBaseHelper();

    List<int> quotesToLoadList = getQuotesNumberToLoad(selectedList.length);
    await databaseHelper.deleteAllQuotes();

    for (var i = 0; i < selectedList.length; i++) {
      List<Quote>? quoteList = await QuotesRemoteDatasource()
          .getQuotes(category: selectedList[i], limit: quotesToLoadList[i]);
      if (quoteList != null) {
        for (var quote in quoteList) {
          databaseHelper.insertQuote(quote);
        }
      }
    }
  }

//get number of quotes to load. Total =15, if there are 5 cat then return= [3, 3, 3, 3, 3,0 ]
  List<int> getQuotesNumberToLoad(int quotesCatLen) {
    int totalQuotes = 15;
    int quotesCategoryLen = quotesCatLen;
    List<int> finalQuotesCategoryNumber = List<int>.filled(6, 0);

    while (totalQuotes != 0) {
      for (int i = 0; i < quotesCategoryLen; i++) {
        if (totalQuotes == 0) {
          break;
        } else {
          finalQuotesCategoryNumber[i]++;
          totalQuotes--;
        }
      }
    }
    return finalQuotesCategoryNumber;
  }
}
