class DbTables {
  static const transactions = 'transactions';
  static const categories = 'categories';
  static const settings = 'settings';
  static const legacySpendings = 'spendings';
}

class DbCols {
  static const id = 'id';
  static const title = 'title';
  static const amount = 'amount';
  static const date = 'date';
  static const categoryId = 'categoryId';
  static const name = 'name';
  static const description = 'description';
  static const icon = 'icon';
  static const color = 'color';
  static const isPinned = 'isPinned';
  static const isArchived = 'isArchived';
  static const includeInSpendingAnalysis = 'includeInSpendingAnalysis';
  static const createdAt = 'createdAt';
}

class DbConfig {
  static const databaseVersion = 4;
  static const databaseFile = 'spending_database.db';
}
