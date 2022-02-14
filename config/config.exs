import Config

config :ex_banking, ExBanking, implementation: ExBanking.ExBankingImplementation

config :ex_banking, ExBanking.Wallet, implementation: ExBanking.SigleBalanceWallet

# to use the multi-currency approach Uncomment the line below
# config :ex_banking, ExBanking.Wallet, implementation: ExBanking.MultiCurrencyBalanceWallet
