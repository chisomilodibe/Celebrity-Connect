# StarConnect Hub - Premium Celebrity Engagement Platform

A comprehensive blockchain-based platform built on Stacks that enables verified celebrities to monetize their brand through exclusive content creation, personalized fan interactions, and premium digital experiences.

## Overview

StarConnect Hub provides a secure, transparent platform where:
- **Celebrities** can create profiles, publish premium content, offer personalized services, and withdraw earnings
- **Fans** can purchase exclusive content, request custom interactions, and follow their favorite stars
- **Platform** ensures fair revenue distribution with automated fee collection (5% platform fee)

## Contract Architecture

### Core Data Structures

- **Celebrity Profiles**: Verified celebrity accounts with biographical information and statistics
- **Content Catalog**: Premium content items with pricing and access control
- **Interaction Requests**: Custom fan-celebrity interaction services
- **Financial Accounts**: Celebrity earnings tracking and withdrawal management
- **Following System**: Social connections between fans and celebrities

### Revenue Model

- Platform takes 5% (500 basis points) from all transactions
- Celebrities retain 95% of their earnings
- Automated revenue distribution on each transaction

## Core Features

### Celebrity Management
- Profile registration and verification
- Content publishing and pricing
- Service configuration (messages, videos, autographs)
- Earnings withdrawal system

### Fan Engagement
- Premium content purchasing
- Personalized interaction requests
- Celebrity following system
- Access verification

### Platform Administration
- Celebrity verification system
- Revenue collection
- Analytics and monitoring

## Contract Functions

### Celebrity Functions

#### `register-celebrity-profile`
Register a new celebrity profile on the platform.

**Parameters:**
- `celebrity-display-name` (string-ascii 50): Display name
- `biography-content` (string-utf8 500): Professional biography
- `profile-image-link` (string-ascii 200): Profile image URL

**Example:**
```clarity
(contract-call? .starconnect-hub register-celebrity-profile 
  "John Doe" 
  "Award-winning actor and producer" 
  "https://example.com/profile.jpg")
```

#### `modify-celebrity-profile-details`
Update existing celebrity profile information.

#### `configure-service-pricing-structure`
Set pricing for different interaction services.

**Parameters:**
- `message-service-price` (uint): Price for personal messages
- `video-service-price` (uint): Price for custom videos
- `autograph-service-price` (uint): Price for digital autographs

#### `publish-premium-content`
Publish new premium content for fan purchase.

**Parameters:**
- `content-title-text` (string-utf8 100): Content title
- `content-description-text` (string-utf8 500): Content description
- `content-media-type` (string-ascii 20): Media type (premium-video, exclusive-audio, digital-artwork, written-content)
- `content-access-price` (uint): Price in microSTX
- `content-hosting-url` (string-ascii 200): Content storage URL

#### `fulfill-interaction-request`
Respond to and complete fan interaction requests.

#### `process-earnings-withdrawal`
Withdraw available earnings to celebrity wallet.

### Fan Functions

#### `purchase-premium-content-access`
Purchase access to celebrity premium content.

**Parameters:**
- `target-content-identifier` (uint): Content ID to purchase

#### `submit-personalized-interaction-request`
Request personalized interaction from celebrity.

**Parameters:**
- `target-celebrity-wallet-address` (principal): Celebrity's wallet address
- `requested-interaction-type` (string-ascii 20): Service type (personal-message, custom-video, digital-autograph)
- `fan-message-content` (string-utf8 500): Fan's message or request

#### `establish-celebrity-following`
Follow a celebrity to stay updated with their content.

#### `remove-celebrity-following`
Unfollow a celebrity.

### Read-Only Functions

#### `retrieve-celebrity-profile-data`
Get celebrity profile information.

#### `retrieve-celebrity-pricing-information`
Get celebrity service pricing.

#### `retrieve-content-details`
Get details about specific content.

#### `verify-fan-content-purchase-status`
Check if fan has purchased specific content.

#### `retrieve-platform-analytics-summary`
Get platform statistics and analytics.

## Security Features

### Input Validation
- String length validation for all text inputs
- Content type validation
- Positive number validation
- Duplicate prevention mechanisms

### Access Control
- Celebrity-only functions protected by registration checks
- Administrator functions restricted to platform owner
- Self-interaction prevention (users can't interact with themselves)

### Financial Security
- Automated revenue sharing
- Balance verification before withdrawals
- Transaction atomicity guarantees

## Economic Model

### Default Service Pricing
- Personal Messages: 1 STX (1,000,000 microSTX)
- Custom Videos: 5 STX (5,000,000 microSTX)
- Digital Autographs: 2 STX (2,000,000 microSTX)

### Revenue Distribution
- **Platform Fee**: 5% of all transactions
- **Celebrity Earnings**: 95% of all transactions
- **Automatic Processing**: Revenue split occurs on each transaction

## Platform Analytics

The contract tracks comprehensive analytics including:
- Total registered celebrities
- Total published content items
- Total completed interactions
- Platform revenue metrics

## Getting Started

### For Celebrities

1. **Register**: Call `register-celebrity-profile` with your information
2. **Get Verified**: Wait for platform administrator verification
3. **Set Pricing**: Configure your service prices with `configure-service-pricing-structure`
4. **Create Content**: Publish premium content using `publish-premium-content`
5. **Engage Fans**: Respond to interaction requests and fulfill services
6. **Withdraw Earnings**: Use `process-earnings-withdrawal` to access your funds

### For Fans

1. **Discover**: Browse celebrity profiles and content
2. **Purchase**: Buy premium content access
3. **Request**: Submit personalized interaction requests
4. **Follow**: Stay connected with your favorite celebrities
5. **Engage**: Enjoy exclusive content and personalized experiences

## Error Handling

The contract includes comprehensive error handling with specific error codes:

- `u100`: Unauthorized access
- `u101`: Resource not found
- `u102`: Duplicate resource
- `u103`: Insufficient balance
- `u104`: Invalid amount
- `u105`: Invalid input parameters
- `u106`: Content unavailable
- `u107`: Duplicate purchase
- `u108`: Self-interaction prohibited

## Smart Contract Deployment

Deploy to Stacks blockchain using Clarinet:

```bash
clarinet deploy --network testnet
```