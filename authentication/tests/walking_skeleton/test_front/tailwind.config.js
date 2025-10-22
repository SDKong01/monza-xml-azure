const { fontFamily } = require("tailwindcss/defaultTheme")

module.exports = {
    darkMode: ["class"],
    content: [
        "./pages/**/*.{js,ts,jsx,tsx}",
        "./components/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        container: {
            center: true,
            padding: "2rem",
            screens: {
                "2xl": "1400px",
            },
        },
        extend: {
            keyframes: {
                blinkingDeleteBorder: {
                    '0%, 100%': { border: '2px solid #D32F2F' },
                    '50%': { border: '2px solid #FFFFFF' },
                },
                blinkingSuccessBorder: {
                    '0%, 100%': { border: '2px solid #2E7D32' },
                    '50%': { border: '2px solid #FFFFFF' },
                },
                "accordion-down": {
                    from: { height: "0" },
                    to: { height: "var(--radix-accordion-content-height)" },
                },
                "accordion-up": {
                    from: { height: "var(--radix-accordion-content-height)" },
                    to: { height: "0" },
                },
            },
            animation: {
                blinkingDeleteBorder: 'blinkingDeleteBorder 2s ease-in-out infinite',
                blinkingSuccessBorder: 'blinkingSuccessBorder 2s ease-in-out infinite',
                "accordion-down": "accordion-down 0.2s ease-out",
                "accordion-up": "accordion-up 0.2s ease-out",
            },
            fontFamily: {
                nunito: ['Nunito Sans', 'sans-serif'],
                mulish: ['Mulish', 'sans-serif'],
                roboto: ['Roboto', 'sans-serif'],
                sans: ["var(--font-sans)", ...fontFamily.sans],
            },
            fontSize: {
                small: '0.688rem',
            },
            boxShadow: {
                headerShadow: "rgba(0, 0, 0, 0.35) 0px -2px 6px",
                modelShadow: "0px 4px 24px 0px rgba(0, 0, 0, 0.14)",
                importBox: "0px 6.55px 24.563px 0px rgba(0, 0, 0, 0.15)",
                nextTopper: " 0px 3px 1px -2px rgba(0, 0, 0, 0.20), 0px 2px 2px 0px rgba(0, 0, 0, 0.14), 0px 1px 5px 0px rgba(0, 0, 0, 0.12)",
                importfileBox: " 0px 2px 1px -1px rgba(0, 0, 0, 0.20), 0px 1px 1px 0px rgba(0, 0, 0, 0.14), 0px 1px 3px 0px rgba(0, 0, 0, 0.12)",
                loginBoxShadow: "0px 8.033px 30.122px 0px rgba(0, 0, 0, 0.15)",
                plusIconBoxShadow: "0px 3px 5px -1px rgba(0, 0, 0, 0.20), 0px 6px 10px 0px rgba(0, 0, 0, 0.14), 0px 1px 18px 0px rgba(0, 0, 0, 0.12)"
            },
            backgroundImage: {
                'radial-gradient-green': 'radial-gradient(circle, rgba(220,252,231,1) 0%, rgba(241,245,249,1) 100%)',
                'radial-gradient-gray': 'radial-gradient(circle, rgb(148 163 184) 0%, rgba(241,245,249,1) 100%)',
                'radial-gradient-indigo': 'radial-gradient(circle, rgb(165 180 252) 0%, rgba(241,245,249,1) 100%)',
                'radial-gradient-amber': 'radial-gradient(circle, rgb(252 211 77) 0%, rgba(241,245,249,1) 100%)',
                'linear-gradient-yellow': 'linear-gradient(180deg, rgba(251,191,36,1) 0%, rgba(226,232,240,1) 100%)',
                'linear-gradient-yellow-90-deg': 'linear-gradient(90deg, rgba(251,191,36,1) 0%, rgba(226,232,240,1) 100%)',
                'linear-gradient-gray': 'linear-gradient(180deg, rgba(226, 232, 240, 1) 90%, rgb(255 255 255 / 50%) 100%)',
            },
            backgroundColor: {
                primary: "#22C55E",
                white: "#FFFFFF",
                error: '#D32F2F',
                success: '#2E7D32',
                warning: '#EF6C00',
                red: '#D32F2F',
                info: '#0288D1',
                neutral: '#000000',
                page: '#DADADA',
                lightestBlue: '#EFF6FF'
            },
            borderColor: {
                primary: "#22C55E",
                error: '#D32F2F',
                success: '#2E7D32',
            },
            border: {
                importBorder: '#1FC777',
                selectBorder: 'rgba(0, 0, 0, 0.25)',
            },
            borderRadius: {
                '32.13': '32.13px',
                lg: `var(--radius)`,
                md: `calc(var(--radius) - 2px)`,
                sm: "calc(var(--radius) - 4px)",
            },
            colors: {
                color: {
                    primary: "#22C55E",
                    graylight: "#1B2228",
                    secondary: "#616267DE",
                    white: "#FFFFFF",
                    enabledGreen: "#22DD84",
                    focusGreen: "#1FC777",
                    negro: "#08272C",
                    hovered: "#092556",
                    gray: "#555F6A",
                    lightGray: "#E0E4EB",
                    focused: "#1352BF",
                    disabled: "#7C7E82",
                    disabledDutton: "#D6D7D8",
                    borderHover: "#22DD84",
                    waitingLabel: "#75818c",
                    stepBorder: "#BDBDBD",
                    steptext: "rgba(97, 98, 103, 0.87)",
                    error: "#D32F2F",
                    success: "#2E7D32",
                    gemini: '#f0f4f9',
                    disabledText: "#8B8B8B",
                    foundationBlue: "#E7EEF9",
                    headerblue: "#1E3A8A",
                    calendarColor: "#14532D",
                    dialogTitle: "#0F172A",
                },
                background: {
                    warning: '#FFF4E5',
                    tag: '#00000014',
                    dark: "#092556",
                    gray: "#D6D7D8",
                    waitingLabelBg: "rgba(0, 0, 0, 0.08)",
                },
                macazan: {
                    green: "#0BAFAA",
                    lightgreen: "#E6F8F5",
                    pink: "#FF3366",
                    darkgray: "#424242",
                    lightgray: "#999999",
                    black: "#054846",
                },
            },
        },
    },
    plugins: [
        require("tailwindcss-animate"),
        require("@tailwindcss/forms"),
        function ({ addUtilities }) {
            addUtilities({
                '.h-screen-minus-100': {
                    height: 'calc(100vh - 100px)',
                },
            }, ['responsive', 'hover']);
        }],
};
