import 'package:flutter/material.dart';

class WalletProvider with ChangeNotifier {
  String? _walletAddress;
  String _issuerName = "Issuer";

  String? get walletAddress => _walletAddress;
  String get issuerName => _issuerName;

  void setWallet(String address, {String issuerName = "Issuer"}) {
    _walletAddress = address;
    _issuerName = issuerName;
    notifyListeners();
  }


  void clearWallet() {
    _walletAddress = null;
    _issuerName = "Issuer";
    notifyListeners();
  }

  bool get isConnected => _walletAddress != null;
}
