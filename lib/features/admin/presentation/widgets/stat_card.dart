// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:taqy/core/theme/colors.dart';

// class StatCard extends StatelessWidget {
//   final String title;
//   final String value;
//   final IconData? iconData;
//   final String icon;
//   final Color color;
//   final Color textColor;
//   final bool isComplete;

//   const StatCard({
//     super.key,
//     this.iconData,
//     required this.title,
//     required this.value,
//     this.icon = '',
//     required this.color,
//     required this.textColor,
//     this.isComplete = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.15),
//             blurRadius: 5,
//             spreadRadius: .2,
//             offset: Offset(0, 0),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Container(
//                 decoration: BoxDecoration(
//                   color: textColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Row(
//                     children: [
//                       if (iconData != null) Icon(iconData, color: color),
//                       if (icon != '') SvgPicture.asset(icon, color: color),
//                     ],
//                   ),
//                 ),
//               ),

//               Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: textColor,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 8),
//           Text(
//             title,
//             style: TextStyle(
//               color: AppColors.onSurfaceVariant,
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
