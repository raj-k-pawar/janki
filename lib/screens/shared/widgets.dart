import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

// ── Gradient App Bar Header ────────────────────────────────────────────────
class GradientHeader extends StatelessWidget {
  final String title, subtitle;
  final Widget? trailing;
  const GradientHeader({super.key, required this.title, this.subtitle='', this.trailing});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20, right: 20, bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF52B788)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.white70)),
          ],
        )),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const StatCard({super.key, required this.label, required this.value,
      required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.75)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3),
            blurRadius: 8, offset: const Offset(0,4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: Colors.white24, borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 10),
        Text(value, style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        Text(label, style: GoogleFonts.poppins(
            fontSize: 11, color: Colors.white.withOpacity(0.85))),
      ]),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────
class ActionTile extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const ActionTile({super.key, required this.label, required this.subtitle,
      required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0,3))],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
              Text(subtitle, style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textLight)),
            ],
          )),
          Icon(Icons.chevron_right, color: color),
        ]),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  const SectionHeader(this.title, {super.key, this.icon});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 6),
        ],
        Text(title, style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: AppColors.textDark)),
      ]),
    );
  }
}

// ── White Card ────────────────────────────────────────────────────────────
class WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const WhiteCard({super.key, required this.child,
      this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0,3))],
      ),
      child: child,
    );
  }
}

// ── Field Label + Input ───────────────────────────────────────────────────
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const LabeledField({super.key, required this.label, required this.child});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.poppins(
          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      const SizedBox(height: 5),
      child,
    ]);
  }
}

// ── Primary Button ────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  const PrimaryButton({super.key, required this.label, this.onTap,
      this.loading = false, this.icon});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        child: loading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ]),
      ),
    );
  }
}

// ── QR Code Painter ───────────────────────────────────────────────────────
class QrWidget extends StatelessWidget {
  final String data;
  final double size;
  const QrWidget({super.key, required this.data, this.size = 200});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(painter: _QrPainter(data: data)),
    );
  }
}

class _QrPainter extends CustomPainter {
  final String data;
  _QrPainter({required this.data});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1B4332);
    canvas.drawRect(Rect.fromLTWH(0,0,size.width,size.height),
        Paint()..color = Colors.white);
    var hash = data.codeUnits.fold(0, (p, e) => (p * 31 + e) & 0xFFFFFF);
    const cells = 21;
    final cell = size.width / cells;
    void finder(int col, int row) {
      for (int r=0; r<7; r++) for (int c=0; c<7; c++) {
        if (r==0||r==6||c==0||c==6||(r>=2&&r<=4&&c>=2&&c<=4))
          canvas.drawRect(Rect.fromLTWH((col+c)*cell,(row+r)*cell,cell,cell),paint);
      }
    }
    finder(0,0); finder(cells-7,0); finder(0,cells-7);
    for (int r=0; r<cells; r++) for (int c=0; c<cells; c++) {
      if ((r<8&&c<8)||(r<8&&c>=cells-8)||(r>=cells-8&&c<8)) continue;
      hash = (hash*1664525+1013904223)&0xFFFFFFFF;
      if (hash&1==1) canvas.drawRect(
          Rect.fromLTWH(c*cell,r*cell,cell-0.5,cell-0.5),paint);
    }
  }
  @override bool shouldRepaint(_QrPainter o) => o.data != data;
}

// ── Show Snackbar ─────────────────────────────────────────────────────────
void showSnack(BuildContext ctx, String msg, {bool error = false}) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Text(msg, style: GoogleFonts.poppins()),
    backgroundColor: error ? AppColors.error : AppColors.success,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));
}

// ── Date Key ──────────────────────────────────────────────────────────────
String dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
bool sameDay(DateTime a, DateTime b) => a.year==b.year && a.month==b.month && a.day==b.day;
