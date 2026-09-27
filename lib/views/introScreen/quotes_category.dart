import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/introScreen/quotes_category_controller.dart';

class QuotesCategoryPage extends StatefulWidget {
  static const String routeName = "/selectQuotesCategory";
  const QuotesCategoryPage({super.key});

  @override
  State<QuotesCategoryPage> createState() => _QuotesCategoryPageState();
}

class _QuotesCategoryPageState extends State<QuotesCategoryPage> {
  final c = Get.put(QuotesCategoryController());
  @override
  void initState() {
    // QoutesRepo.getQuotes(category: "love");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            highlightColor: Colors.transparent,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 30,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        title: const Text(
          "Select Quotes category",
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 50,
                ),
              ),
              const SliverToBoxAdapter(
                child: Text(
                  'Select your favourite quotes category to get quotes recommendation',
                  textAlign: TextAlign.center,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 50,
                ),
              ),
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            c.categoryTap(c.quoteItems[index]);
                          },
                          child: Card(
                            margin: const EdgeInsets.only(
                              right: 10,
                              bottom: 20,
                              left: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                            elevation: 10,
                            semanticContainer: false,
                            surfaceTintColor: theme.colorScheme.surfaceTint,
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                c.quoteItems[index][0].toString().toUpperCase() +
                                    c.quoteItems[index]
                                        .toString()
                                        .substring(1)
                                        .toLowerCase(),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 15,
                          top: 10,
                          child: GetBuilder<QuotesCategoryController>(
                            builder: ((controller) => controller
                                    .isSelected(controller.quoteItems[index])
                                ? const Icon(
                                    Icons.task_alt_rounded,
                                  )
                                : Container()),
                          ),
                        ),
                      ],
                    );
                  },
                  childCount: c.quoteItems.length,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          heroTag: "goButtonLoading",
          key: UniqueKey(),
          onPressed: () {
            c.onGoTap();
          },
          icon: const Icon(Icons.subdirectory_arrow_right_rounded),
          label: const Text(
            "Go",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          )),
    );
  }
}
