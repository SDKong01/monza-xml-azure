# Test Frontend

This is a test frontend application that replicates the styling and components from the main EZML Frontend codebase.

## Features

- **Login Screen**: A fully styled login form matching the original design
- **Same Styling**: Uses identical Tailwind CSS configuration and custom components
- **No Functionality**: Pure UI demonstration without authentication logic
- **Port 3001**: Runs on a different port to avoid conflicts with the main app

## Getting Started

### Prerequisites

- Node.js 18+ installed
- npm or yarn package manager

### Installation

1. Navigate to the test frontend directory:
   ```bash
   cd test_front
   ```

2. Install dependencies:
   ```bash
   npm install
   # OR
   yarn install
   ```

3. Start the development server:
   ```bash
   npm run dev
   # OR
   yarn dev
   ```

4. Open your browser and navigate to:
   ```
   http://localhost:3001
   ```

## What You'll See

- **Header**: KAINAM logo in the top center
- **Welcome Section**: Large "Welcome" text with subtitle
- **Login Form**: Email and password fields with show/hide password toggle
- **Buttons**: Styled login button and sign-up link
- **Footer**: Terms, privacy policy, and copyright information

## File Structure

```
test_front/
├── components/
│   ├── common/
│   │   └── PublicHeader.js
│   ├── ui/
│   │   ├── Button.js
│   │   ├── Card.js
│   │   ├── Form.js
│   │   └── Input.js
│   └── icons/
│       └── index.js
├── hooks/
│   ├── useToggle.js
│   └── index.js
├── pages/
│   ├── _app.js
│   └── index.js
├── styles/
│   └── globals.css
├── utils/
│   └── classNames.js
├── package.json
├── next.config.js
├── tailwind.config.js
├── postcss.config.js
└── README.md
```

## Customization

You can modify the login screen by editing:
- **Styling**: `tailwind.config.js` and `styles/globals.css`
- **Components**: Files in `components/ui/` and `components/common/`
- **Layout**: `pages/index.js`

## Notes

- This is a standalone application that doesn't affect the main codebase
- All styling matches the original application exactly
- No backend integration or authentication is implemented
- Perfect for learning and testing UI changes
