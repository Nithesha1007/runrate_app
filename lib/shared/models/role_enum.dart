/// The 5 supported roles. Drives which role-folder home shell is shown.
enum RoleEnum { ceo, cfo, engineeringManager, employee, orgAdmin }

extension RoleEnumX on RoleEnum {
  String get label {
    switch (this) {
      case RoleEnum.ceo:
        return 'CEO';
      case RoleEnum.cfo:
        return 'CFO';
      case RoleEnum.engineeringManager:
        return 'Engineering Manager';
      case RoleEnum.employee:
        return 'Employee';
      case RoleEnum.orgAdmin:
        return 'Org Admin';
    }
  }
}
