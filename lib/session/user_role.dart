enum UserRole {
  landlord,
  tenant,
  contractor,
  manager,
}

UserRole parseRole(String role) {
  switch (role) {
    case 'landlord':
      return UserRole.landlord;
    case 'tenant':
      return UserRole.tenant;
    case 'contractor':
      return UserRole.contractor;
    default:
      return UserRole.tenant;
  }
}
