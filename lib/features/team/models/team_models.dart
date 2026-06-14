import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

// ── Role constants ─────────────────────────────────────────────────────────────

const kRoleOwner = 'owner';
const kRoleAdmin = 'admin';
const kRoleMember = 'member';

// ── Team color (deterministic from teamId — no backend storage needed) ─────────

Color teamColor(String teamId) {
  const palette = [
    AppColors.primary,
    Color(0xFF8B5CF6), // violet
    Color(0xFF06B6D4), // cyan
    Color(0xFF22C55E), // green
    Color(0xFFF97316), // orange
    Color(0xFF3B82F6), // blue
  ];
  return palette[teamId.hashCode.abs() % palette.length];
}

// ── Role helpers ───────────────────────────────────────────────────────────────

String roleLabel(String role) => switch (role) {
      kRoleOwner => 'Owner',
      kRoleAdmin => 'Admin',
      _ => 'Member',
    };

Color roleColor(String role) => switch (role) {
      kRoleOwner => AppColors.primary,
      kRoleAdmin => const Color(0xFF8B5CF6),
      _ => const Color(0xFF64748B),
    };

bool canInvite(String role) => role == kRoleOwner || role == kRoleAdmin;
bool canRemove(String role) => role == kRoleOwner || role == kRoleAdmin;

// ── Map accessors (team) ───────────────────────────────────────────────────────

String teamId(Map m) => m['id'] as String? ?? '';
String teamName(Map m) => m['name'] as String? ?? 'Unnamed Team';
String teamDesc(Map m) => m['description'] as String? ?? '';
String teamOwnerId(Map m) => m['ownerId'] as String? ?? '';
int teamMemberCount(Map m) => (m['memberCount'] as num?)?.toInt() ?? 0;
double teamCompletionRate(Map m) =>
    (m['completionRate'] as num?)?.toDouble() ?? 0.0;

// ── Map accessors (member) ─────────────────────────────────────────────────────

String memberId(Map m) => m['id'] as String? ?? '';
String memberUserId(Map m) => m['userId'] as String? ?? '';
String memberName(Map m) => m['name'] as String? ?? 'Unknown';
String memberEmail(Map m) => m['email'] as String? ?? '';
String memberRole(Map m) => m['role'] as String? ?? kRoleMember;
int memberAssigned(Map m) => (m['tasksAssigned'] as num?)?.toInt() ?? 0;
int memberCompleted(Map m) => (m['tasksCompleted'] as num?)?.toInt() ?? 0;
String? memberAvatar(Map m) => m['avatarUrl'] as String?;

double memberCompletion(Map m) {
  final assigned = memberAssigned(m);
  if (assigned == 0) return 0;
  return memberCompleted(m) / assigned;
}

String memberInitials(Map m) {
  final name = memberName(m);
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}

// ── Map accessors (invite) ────────────────────────────────────────────────────

String inviteId(Map m) => m['id'] as String? ?? '';
String inviteTeamId(Map m) => m['teamId'] as String? ?? '';
String inviteTeamName(Map m) => m['teamName'] as String? ?? '';
String inviterName(Map m) => m['inviterName'] as String? ?? '';
String inviteStatus(Map m) => m['status'] as String? ?? 'pending';
bool inviteIsPending(Map m) => inviteStatus(m) == 'pending';

// ── Map accessors (progress) ──────────────────────────────────────────────────

int progressCompleted(Map m) => (m['completedTasks'] as num?)?.toInt() ?? 0;
int progressTotal(Map m) => (m['totalTasks'] as num?)?.toInt() ?? 0;
double progressRate(Map m) => (m['completionRate'] as num?)?.toDouble() ?? 0.0;

List<Map<String, dynamic>> progressMembers(Map m) =>
    (m['memberProgress'] as List?)?.cast<Map<String, dynamic>>() ?? [];

List<Map<String, dynamic>> progressActivity(Map m) =>
    (m['recentActivity'] as List?)?.cast<Map<String, dynamic>>() ?? [];

// ── Shared / assigned task helpers ────────────────────────────────────────────

String taskAssigneeName(Map m) => m['assigneeName'] as String? ?? '';
bool taskIsShared(Map m) => m['isShared'] == true;
String taskOwnerName(Map m) => m['ownerName'] as String? ?? '';
