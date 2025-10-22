import { clsx } from "keycloakify/tools/clsx";
import { useState } from "react";
import type { KcContext } from "../KcContext";
import type { I18n } from "../i18n";

export default function Login(props: {
    kcContext: KcContext & { pageId: "login.ftl" };
    i18n: I18n;
    doUseDefaultCss: boolean;
    classes?: Partial<Record<string, string>>;
}) {
    const { kcContext, i18n } = props;
    const { msg, msgStr } = i18n;
    const {
        realm,
        url,
        usernameHidden,
        login,
        auth,
        registrationDisabled,
        message
    } = kcContext;

    const [isLoginButtonDisabled, setIsLoginButtonDisabled] = useState(false);
    const [showPassword, setShowPassword] = useState(false);

    return (
        <div className="flex flex-col w-full bg-slate-100 min-h-screen font-nunito">
            {/* Header Section */}
            <div className="h-full pt-20 pb-12 flex flex-col bg-slate-100">
                {/* Welcome Title */}
                <div className="max-w-80 mx-auto text-center mb-14">
                    <h1 className="kc-welcome-title">Welcome</h1>
                    <p className="kc-welcome-subtitle">Please enter your credentials</p>
                </div>

                {/* Login Card */}
                <div className="kc-card mx-auto">
                    {/* Kainam Logo */}
                    <div className="flex justify-center mb-6">
                        <img
                            src={`${url.resourcesPath}/kainam-logo.png`}
                            alt="Kainam Logo"
                            className="h-12"
                        />
                    </div>

                    <h2 className="text-center font-bold text-slate-900 text-xl mb-6">
                        Login
                    </h2>

                    {/* Error Message */}
                    {message !== undefined && message.type === "error" && (
                        <div className="kc-alert-error">
                            <span className="flex items-center gap-2">
                                <svg
                                    className="w-5 h-5"
                                    fill="currentColor"
                                    viewBox="0 0 20 20"
                                >
                                    <path
                                        fillRule="evenodd"
                                        d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                                        clipRule="evenodd"
                                    />
                                </svg>
                                <span dangerouslySetInnerHTML={{ __html: message.summary }} />
                            </span>
                        </div>
                    )}

                    {/* Login Form */}
                    <form
                        id="kc-form-login"
                        onSubmit={() => {
                            setIsLoginButtonDisabled(true);
                            return true;
                        }}
                        action={url.loginAction}
                        method="post"
                    >
                        {/* Email/Username Field */}
                        <div className="mb-6">
                            <label
                                htmlFor="username"
                                className={clsx(
                                    "kc-label",
                                    message?.type === "error" && "kc-label-error"
                                )}
                            >
                                {!realm.loginWithEmailAllowed
                                    ? msg("username")
                                    : !realm.registrationEmailAsUsername
                                        ? msg("usernameOrEmail")
                                        : msg("email")}
                            </label>
                            <input
                                tabIndex={1}
                                id="username"
                                className={clsx(
                                    "kc-input",
                                    message?.type === "error" && "kc-input-error"
                                )}
                                name="username"
                                defaultValue={login.username ?? ""}
                                type="text"
                                autoFocus={true}
                                autoComplete="username"
                                placeholder={msgStr("email")}
                                aria-invalid={message?.type === "error"}
                            />
                        </div>

                        {/* Password Field */}
                        <div className="mb-6">
                            <label
                                htmlFor="password"
                                className={clsx(
                                    "kc-label",
                                    message?.type === "error" && "kc-label-error"
                                )}
                            >
                                {msg("password")}
                            </label>
                            <div className="relative">
                                <input
                                    tabIndex={2}
                                    id="password"
                                    className={clsx(
                                        "kc-input pr-10",
                                        message?.type === "error" && "kc-input-error"
                                    )}
                                    name="password"
                                    type={showPassword ? "text" : "password"}
                                    autoComplete="current-password"
                                    placeholder="Password"
                                    aria-invalid={message?.type === "error"}
                                />
                                <button
                                    type="button"
                                    className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                                    onClick={() => setShowPassword(!showPassword)}
                                    aria-label={showPassword ? "Hide password" : "Show password"}
                                >
                                    {showPassword ? (
                                        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                                        </svg>
                                    ) : (
                                        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                        </svg>
                                    )}
                                </button>
                            </div>
                        </div>

                        {/* Remember Me & Forgot Password Row */}
                        <div className="flex justify-between items-center mb-6">
                            {realm.rememberMe && !usernameHidden && (
                                <div className="flex items-center">
                                    <input
                                        tabIndex={3}
                                        id="rememberMe"
                                        name="rememberMe"
                                        type="checkbox"
                                        defaultChecked={!!login.rememberMe}
                                        className="w-4 h-4 text-green-700 bg-white border-slate-300 rounded focus:ring-green-700 focus:ring-2"
                                    />
                                    <label
                                        htmlFor="rememberMe"
                                        className="ml-2 text-sm text-slate-600 font-semibold cursor-pointer"
                                    >
                                        {msg("rememberMe")}
                                    </label>
                                </div>
                            )}
                            {realm.resetPasswordAllowed && (
                                <a href={url.loginResetCredentialsUrl} className="kc-link ml-auto">
                                    {msg("doForgotPassword")}
                                </a>
                            )}
                        </div>

                        {/* Login Button */}
                        <div className="mb-4">
                            <input
                                type="hidden"
                                id="id-hidden-input"
                                name="credentialId"
                                value={auth?.selectedCredential}
                            />
                            <button
                                tabIndex={4}
                                className={clsx(
                                    "kc-button-primary",
                                    isLoginButtonDisabled && "opacity-50 cursor-not-allowed"
                                )}
                                name="login"
                                id="kc-login"
                                type="submit"
                                disabled={isLoginButtonDisabled}
                            >
                                {msgStr("doLogIn")}
                            </button>
                        </div>
                    </form>

                    {/* Sign Up Link */}
                    {realm.password && realm.registrationAllowed && !registrationDisabled && (
                        <div className="text-center mt-6">
                            <span className="text-base text-slate-600 font-semibold">
                                Don't have an account?{" "}
                                <a href={url.registrationUrl} className="kc-link">
                                    Sign Up
                                </a>
                            </span>
                        </div>
                    )}
                </div>

                {/* Footer */}
                <div className="mt-11 max-w-[714px] mx-auto text-center">
                    <p className="kc-footer-text">
                        By using Kainam you agree to our{" "}
                        <a href="#" className="kc-footer-link">
                            Terms and Conditions
                        </a>{" "}
                        and{" "}
                        <a href="#" className="kc-footer-link">
                            Privacy Policy
                        </a>
                        .
                    </p>
                    <p className="kc-footer-text mt-4">
                        © {new Date().getFullYear()} Kainam. All rights reserved.
                    </p>
                </div>
            </div>
        </div>
    );
}

