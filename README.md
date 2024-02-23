# About

Nerd is an educational/entertainment ERC-20 token. 

# Deployment

Contract has been deployed on the Ethereum mainnet.  
NERD: `0xaf20f01d515bd95fef560b8dd49b493af180bda6`  
NERDs (Nerd Sale Right): `0xEA577e0dd93569E8b6634B1f7C8Ca0DAf6EAF306` 

# Common questions

**Q: What is the purpose of NERD tokens in the project?**

**A:** NERD tokens serve as both an educational and entertaining digital asset. They are not meant for financial returns.

**Q: Why can't I sell NERD tokens without NERDs?**

**A:** Selling NERD tokens without NERDs is restricted. NERDs are earned through, for example, the staking process, and they provide special privileges in the project's ecosystem. It's important to note that when buying NERD in the main Uniswap pool, half of the amount in NERDs is airdropped directly to the wallet – meaning you can sell immediately half of what you bought. For the other half, you need to acquire sale rights through activities within the project.

**Q: How does staking work in the NERD project?**

**A:** Staking NERD tokens involves locking them to earn rewards, specifically NERDs. The staking rate increases incrementally over time, encouraging long-term participation.

**Q: How do I participate in the NERD auction?**

**A:** To participate in the auction, bid with your NERD tokens. The winning bidder receives Sale Rights (NERDs) and enjoys exclusive benefits within the project.

**Q: Why is staking important in the NERD project?**

**A:** Staking NERD tokens is crucial for earning additional NERDs. The incremental staking rate encourages long-term commitment and active engagement, contributing to the overall growth of the project.


# Development

Project uses [Foundry](https://github.com/foundry-rs/foundry), install it first.

```
git pull git@github.com:nerdeth/token-contract.git
cd token-contract
git submodule update --init --recursive
forge test
```

