import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:scalextric/components/formatted_duration.dart';
import 'package:scalextric_shared/models/user.dart';

import 'package:zeta_flutter/zeta_flutter.dart';

class IdCard extends StatelessWidget {
  const IdCard({super.key, this.data, this.title, this.onTap, this.heroId});

  final User? data;
  final String? title;
  final VoidCallback? onTap;
  final String? heroId;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (title != null)
          SizedBox(
            width: 600,
            height: 250,
            child: Text(
              title!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 82, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        const SizedBox(height: 20),
        Hero(
          tag: heroId ?? 'id-card',
          child: InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: onTap,
            child: Container(
              width: 542,
              height: 344,
              decoration: ShapeDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(0.93, -0.36),
                  end: const Alignment(-0.93, 0.36),
                  colors: [
                    Colors.white.withAlpha(0.3 * 255 ~/ 1),
                    Colors.white.withAlpha(0.05 * 255 ~/ 1),
                  ],
                ),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1.47,
                    color: Colors.white.withAlpha(0.3 * 255 ~/ 1),
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                shadows: const [
                  BoxShadow(color: Color(0x19000000), blurRadius: 58.88, offset: Offset(0, 29.44)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [Icon(ZetaIcons.barcode_qr_code, color: Colors.white, size: 62)],
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (data != null)
                                SizedBox(
                                  height: 126,
                                  child: SingleChildScrollView(
                                    child: Text(
                                      data!.name.trim(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                      ),
                                    ),
                                  ),
                                ),
                              if (data != null && data?.fastestLap != null && data?.attempts != null)
                                Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Previous best:',
                                          style: TextStyle(color: Colors.white, fontSize: 24),
                                        ),
                                        FormattedDuration(
                                          Duration(milliseconds: data!.fastestLap!),
                                          style: const TextStyle(color: Colors.white, fontSize: 24),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Attempts:',
                                          style: TextStyle(color: Colors.white, fontSize: 24),
                                        ),
                                        Text(
                                          '${data!.attempts}',
                                          style: const TextStyle(color: Colors.white, fontSize: 24),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 8),
                            ].gap(8),
                          ),
                        ),
                      ].gap(20),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
