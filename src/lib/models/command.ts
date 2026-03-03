export interface Command {
  execute(): Promise<void>;
  undo(): Promise<void>;
  description: string;
}

export class AddTransactionCommand implements Command {
  description: string;

  constructor(
    private transactionId: string,
    private transactionData: Record<string, unknown>,
    private deleteTransaction: (id: string) => Promise<void>,
    private addTransaction: (data: Record<string, unknown>) => Promise<void>
  ) {
    this.description = `Add transaction: ${transactionData.description}`;
  }

  async execute() {
    await this.addTransaction(this.transactionData);
  }

  async undo() {
    await this.deleteTransaction(this.transactionId);
  }
}

export class DeleteTransactionCommand implements Command {
  description: string;

  constructor(
    private transactionId: string,
    private transactionData: Record<string, unknown>,
    private deleteTransaction: (id: string) => Promise<void>,
    private addTransaction: (data: Record<string, unknown>) => Promise<void>
  ) {
    this.description = `Delete transaction: ${transactionData.description}`;
  }

  async execute() {
    await this.deleteTransaction(this.transactionId);
  }

  async undo() {
    await this.addTransaction(this.transactionData);
  }
}

export class UpdateTransactionCommand implements Command {
  description: string;

  constructor(
    private oldData: Record<string, unknown>,
    private newData: Record<string, unknown>,
    private updateTransaction: (data: Record<string, unknown>) => Promise<void>
  ) {
    this.description = `Update transaction: ${newData.description}`;
  }

  async execute() {
    await this.updateTransaction(this.newData);
  }

  async undo() {
    await this.updateTransaction(this.oldData);
  }
}

export class UpdateTransactionCategoryCommand implements Command {
  description = 'Move transaction to category';

  constructor(
    private transactionId: string,
    private oldCategoryId: string,
    private newCategoryId: string,
    private updateCategory: (txId: string, catId: string) => Promise<void>
  ) {}

  async execute() {
    await this.updateCategory(this.transactionId, this.newCategoryId);
  }

  async undo() {
    await this.updateCategory(this.transactionId, this.oldCategoryId);
  }
}
