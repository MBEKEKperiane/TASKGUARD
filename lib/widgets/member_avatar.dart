import 'package:flutter/material.dart';
import '../features/team/models/team_models.dart';
import '../theme/app_colors.dart';

/// Circular avatar for a team member.
/// Shows network image if [avatarUrl] is set, otherwise initials with a
/// deterministic background colour derived from the member's name.
class MemberAvatar extends StatelessWidget {
  final Map<String, dynamic> member;
  final double radius;
  final bool showRoleDot;

  const MemberAvatar({
    super.key,
    required this.member,
    this.radius = 20,
    this.showRoleDot = false,
  });

  Color _bgColor() {
    const palette = [
      AppColors.primary,
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFF22C55E),
      Color(0xFFF97316),
      Color(0xFF3B82F6),
    ];
    final name = memberName(member);
    return palette[name.hashCode.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final url = memberAvatar(member);
    final initials = memberInitials(member);
    final role = memberRole(member);
    final bg = _bgColor();

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      backgroundImage: url != null ? NetworkImage(url) : null,
      child: url == null
          ? Text(initials,
              style: TextStyle(
                  fontSize: radius * 0.7,
                  fontWeight: FontWeight.w700,
                  color: Colors.white))
          : null,
    );

    if (!showRoleDot || role == kRoleMember) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: radius * 0.55,
            height: radius * 0.55,
            decoration: BoxDecoration(
              color: roleColor(role),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Overlapping avatar stack — shows up to [max] avatars + overflow count.
class MemberAvatarStack extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final int max;
  final double radius;

  const MemberAvatarStack({
    super.key,
    required this.members,
    this.max = 4,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final shown = members.take(max).toList();
    final overflow = members.length - shown.length;
    final totalWidth =
        (shown.length + (overflow > 0 ? 1 : 0)) * (radius * 1.4);

    return SizedBox(
      width: totalWidth,
      height: radius * 2,
      child: Stack(
        children: [
          ...shown.asMap().entries.map((e) => Positioned(
                left: e.key * radius * 1.4,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: MemberAvatar(member: e.value, radius: radius),
                ),
              )),
          if (overflow > 0)
            Positioned(
              left: shown.length * radius * 1.4,
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  color: const Color(0xFF94A3B8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text('+$overflow',
                    style: TextStyle(
                        fontSize: radius * 0.65,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}
