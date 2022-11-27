# Requirements for Dutch Auction NFT

🗳️ Auction

    1. Seller of NFT deploys this contract setting a starting price.

    2. Auction lasts for 7 days.

    3. Price of NFT decreases over time.

    4. Participants can buy by depositing ETH greater than the current price computed.

    5. Auction ends when a buyer buys the NFT, refunding excess.

💰 After the auction

    1. Smart contract transfer funds to seller and self destructs.

# Development-Goal

🖼️ Learn how NFT auctions work.
