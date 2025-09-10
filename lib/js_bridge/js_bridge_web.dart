import 'dart:js' as js;
import 'dart:js_util';

void registerApplePayCallback(Function(String) onNonce) {
  js.context['handleApplePayResult'] = allowInterop(onNonce);
}

void startApplePay(String clientToken) {
  js.context.callMethod('startApplePay', [clientToken]);//, 'handleApplePayResult']);
}
