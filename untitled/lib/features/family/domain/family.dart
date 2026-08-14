enum FamilyRole { owner, caregiver }
class FamilyPermissions {
  const FamilyPermissions(this.role);
  final FamilyRole role;
  bool get canManageFamily => role == FamilyRole.owner;
  bool get canRecordEvents => true;
}
