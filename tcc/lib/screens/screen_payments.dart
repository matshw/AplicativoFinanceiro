import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SelectPaymentMethodScreen extends StatelessWidget {
  final Function(String, FaIcon) onPaymentMethodSelected;

  SelectPaymentMethodScreen({required this.onPaymentMethodSelected});

  final Map<String, FaIcon> _paymentMethods = {
    "Dinheiro": const FaIcon(FontAwesomeIcons.moneyBill),
    "Cartão de Crédito": const FaIcon(FontAwesomeIcons.ccVisa),
    "Cartão de Débito": const FaIcon(FontAwesomeIcons.ccMastercard),
    "Transferência Bancária": const FaIcon(FontAwesomeIcons.moneyBillTransfer),
    "Pix": const FaIcon(FontAwesomeIcons.pix),
    "Boleto": const FaIcon(FontAwesomeIcons.file),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(
          'Selecionar Meio de Pagamento',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView.builder(
        itemCount: _paymentMethods.length,
        itemBuilder: (context, index) {
          String methodName = _paymentMethods.keys.elementAt(index);
          FaIcon methodIcon = _paymentMethods[methodName]!;

          return ListTile(
            leading: methodIcon,
            iconColor: Colors.white,
            title: Text(
              methodName,
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              onPaymentMethodSelected(methodName, methodIcon);
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }
}
