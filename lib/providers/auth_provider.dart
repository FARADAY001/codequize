import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/utilisateur.dart';
import '../models/badge_model.dart';
import '../models/niveau.dart';
import '../services/database_service.dart';

/// Gère la session d'authentification : inscription, connexion, déconnexion.
///
/// Les comptes sont désormais persistés dans la base sqflite locale via
/// DatabaseService.
class AuthProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  Utilisateur? _utilisateurCourant;
  String? _erreur;
  bool _enCours = false;

  Utilisateur? get utilisateurCourant => _utilisateurCourant;
  bool get estConnecte => _utilisateurCourant != null;
  String? get erreur => _erreur;
  bool get enCours => _enCours;

  String _hacher(String motDePasse) {
    return sha256.convert(utf8.encode(motDePasse)).toString();
  }

  /// Crée un nouveau compte. Retourne true si l'inscription a réussi.
  Future<bool> inscrire(String nomUtilisateur, String motDePasse) async {
    final nom = nomUtilisateur.trim();

    if (nom.isEmpty || motDePasse.isEmpty) {
      _erreur = "Le nom d'utilisateur et le mot de passe sont obligatoires.";
      notifyListeners();
      return false;
    }

    _enCours = true;
    notifyListeners();

    final existant = await _db.obtenirUtilisateurParNom(nom);
    if (existant != null) {
      _erreur = "Ce nom d'utilisateur existe déjà.";
      _enCours = false;
      notifyListeners();
      return false;
    }

    final nouvelUtilisateur = Utilisateur(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      nomUtilisateur: nom,
      motDePasseHache: _hacher(motDePasse),
      dateCreation: DateTime.now(),
    );

    await _db.creerUtilisateur(nouvelUtilisateur);

    _utilisateurCourant = nouvelUtilisateur;
    _erreur = null;
    _enCours = false;
    notifyListeners();
    return true;
  }

  /// Authentifie un utilisateur existant. Retourne true si succès.
  Future<bool> connecter(String nomUtilisateur, String motDePasse) async {
    _enCours = true;
    notifyListeners();

    final utilisateur = await _db.obtenirUtilisateurParNom(nomUtilisateur.trim());
    final hash = _hacher(motDePasse);

    if (utilisateur == null || utilisateur.motDePasseHache != hash) {
      // Message générique
      _erreur = "Nom d'utilisateur ou mot de passe incorrect.";
      _enCours = false;
      notifyListeners();
      return false;
    }

    _utilisateurCourant = utilisateur;
    _erreur = null;
    _enCours = false;
    notifyListeners();
    return true;
  }

  void deconnecter() {
    _utilisateurCourant = null;
    notifyListeners();
  }

  void effacerErreur() {
    _erreur = null;
    notifyListeners();
  }

  /// Recharge l'utilisateur courant depuis la base.
  Future<void> rafraichirUtilisateurCourant() async {
    if (_utilisateurCourant == null) return;
    final utilisateur = await _db.obtenirUtilisateurParNom(_utilisateurCourant!.nomUtilisateur);
    _utilisateurCourant = utilisateur;
    notifyListeners();
  }

  /// Indique si le défi quotidien a déjà été fait aujourd'hui.
  bool get defiDejaFaitAujourdHui {
    final derniere = _utilisateurCourant?.derniereDateDefi;
    if (derniere == null) return false;
    final aujourdHui = DateTime.now();
    return derniere.year == aujourdHui.year &&
        derniere.month == aujourdHui.month &&
        derniere.day == aujourdHui.day;
  }

  /// Met à jour la série de jours consécutifs après participation au défi
  /// quotidien. Ne fait rien si le défi a déjà été fait aujourd'hui.
  /// Retourne true si la série a été incrémentée.
  Future<bool> enregistrerParticipationDefi() async {
    final utilisateur = _utilisateurCourant;
    if (utilisateur == null || defiDejaFaitAujourdHui) return false;

    final aujourdHui = DateTime.now();
    final aujourdHuiSansHeure = DateTime(aujourdHui.year, aujourdHui.month, aujourdHui.day);
    final derniere = utilisateur.derniereDateDefi;
    final hier = aujourdHuiSansHeure.subtract(const Duration(days: 1));

    final etaitHier = derniere != null &&
        derniere.year == hier.year &&
        derniere.month == hier.month &&
        derniere.day == hier.day;

    final nouvelleSerie = etaitHier ? utilisateur.serieActuelle + 1 : 1;
    final nouvelleMeilleureSerie =
        nouvelleSerie > utilisateur.meilleureSerie ? nouvelleSerie : utilisateur.meilleureSerie;

    final utilisateurMisAJour = utilisateur.copierAvec(
      serieActuelle: nouvelleSerie,
      meilleureSerie: nouvelleMeilleureSerie,
      derniereDateDefi: aujourdHuiSansHeure,
    );

    await _db.mettreAJourUtilisateur(utilisateurMisAJour);
    _utilisateurCourant = utilisateurMisAJour;

    // Badge spécial "série" débloqué tous les 7 jours consécutifs.
    if (nouvelleSerie % 7 == 0) {
      final badge = BadgeModel(
        id: '${DateTime.now().microsecondsSinceEpoch}_serie',
        utilisateurId: utilisateurMisAJour.id,
        langageId: 'global',
        niveau: NiveauType.debutant,
        dateObtention: DateTime.now(),
        type: TypeBadge.serie,
      );
      await _db.enregistrerBadge(badge);
    }

    notifyListeners();
    return true;
  }
}
