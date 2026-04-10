class ScanUserBody {
  ScanUserBody(this.firstName, this.surname, this.email, this.company);
  // ScanUserBody(this.firstName, this.surname, this.country, this.email, this.company);

  factory ScanUserBody.fromJsonString(String jsonString) {
    var firstName = '';
    var surname = '';
    // var country = '';
    var company = '';
    var email = '';

    final parts = jsonString.split(';');

    if (parts.length >= 2) {
      firstName = parts[0];
      surname = parts[1];
      // country = parts.length > 2 ? parts[2] : '';
      email = parts.length >= 3 ? parts[2] : '';
      company = parts.length >= 4 ? parts[3] : '';
    } else {
      throw const FormatException('Invalid scan result format');
    }

    return ScanUserBody(firstName, surname, email, company);
    // return ScanUserBody(firstName, surname, country, email, company);
  }

  final String firstName;
  final String surname;
  // final String country;
  final String email;
  final String company;

  Map<String, dynamic> toJson() => {'name': '$firstName $surname', 'id': email};
}
