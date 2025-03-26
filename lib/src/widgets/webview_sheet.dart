// import 'package:flutter/material.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// class WebviewSheet extends StatefulWidget {
//   const WebviewSheet({
//     super.key,
//     required this.url,
//   });
//   final String url;

//   @override
//   State<WebviewSheet> createState() => _WebviewSheetState();
// }

// class _WebviewSheetState extends State<WebviewSheet> {
//   final browser = MyChromeSafariBrowser();

//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.5,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8.0),
//       ),

//       //!
//       child: Column(
//         children: [
//           Align(
//             alignment: Alignment.centerLeft,
//             child: IconButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               icon: Icon(Icons.arrow_back),
//             ),
//           ),
//           // AppBar(
//           //   centerTitle: true,
//           //   title: widget.title.isNotEmpty
//           //       ? widget.title.txt16()
//           //       : switch (widget.url.contains("privacy")) {
//           //           true => "Privacy Policy".txt16(),
//           //           false => "Terms & Conditions ".txt16(),
//           //         },
//           // ),

//           //!
//           Expanded(
//             child: InAppWebView(
//               initialUrlRequest: URLRequest(url: WebUri(widget.url)),
//               initialOptions: InAppWebViewGroupOptions(
//                 android: AndroidInAppWebViewOptions(
//                   useHybridComposition: true,
//                 ),
//                 ios: IOSInAppWebViewOptions(
//                   allowsInlineMediaPlayback: true,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class MyChromeSafariBrowser extends ChromeSafariBrowser {
//   @override
//   void onOpened() {
//     print("ChromeSafari browser opened");
//   }

//   @override
//   void onCompletedInitialLoad(didLoadSuccessfully) {
//     print("ChromeSafari browser initial load completed");
//   }

//   @override
//   void onClosed() {
//     print("ChromeSafari browser closed");
//   }
// }

// class AndroidTWABrowser extends ChromeSafariBrowser {
//   @override
//   void onOpened() {
//     print("Android TWA browser opened");
//   }

//   @override
//   void onCompletedInitialLoad(didLoadSuccessfully) {
//     print("Android TWA browser initial load completed");
//   }

//   @override
//   void onClosed() {
//     print("Android TWA browser closed");
//   }
// }
