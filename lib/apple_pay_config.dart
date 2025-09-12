// lib/apple_pay_config.dart
const applePayJson = '''
{
  "provider": "apple_pay",
  "data": {  
    "merchantIdentifier": "merchant.com.marikpetros",
    "displayName": "PowerBank App",
    "merchantCapabilities": ["3DS"],
    "supportedNetworks": ["visa", "masterCard", "amex"],
    "countryCode": "US",
    "currencyCode": "USD",
    "environment": "sandbox"
  }
}
''';
