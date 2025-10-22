/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {
            colors: {
                'green': {
                    100: '#dcfce7',
                    700: '#15803d',
                },
                'slate': {
                    100: '#f1f5f9',
                    300: '#cbd5e1',
                    400: '#94a3b8',
                    500: '#64748b',
                    600: '#475569',
                    900: '#0f172a',
                },
            },
            fontFamily: {
                'nunito': ['Nunito', 'sans-serif'],
            },
        },
    },
    plugins: [
        require('@tailwindcss/forms'),
    ],
}

