import React, { useState } from 'react';
import PublicHeader from '../components/common/PublicHeader';
import { Button } from '../components/ui/Button';
import { Card } from '../components/ui/Card';
import { useToggle } from '../hooks';

const LoginPage = () => {
    const [show, toggleShow] = useToggle(false);
    const [formData, setFormData] = useState({
        email: '',
        password: ''
    });

    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: value
        }));
    };

    const handleSubmit = (e) => {
        e.preventDefault();
        // No functionality - just prevent default form submission
        console.log('Form submitted:', formData);
    };

    const handleLoginClick = () => {
        // Redirect to OAuth2 Proxy for authentication
        window.location.href = process.env.NEXT_PUBLIC_OAUTH2_PROXY_URL;
    };

    return (
        <>
            <div className="flex flex-col w-full bg-slate-100 !h-auto min-h-[100vh]">
                <PublicHeader />
                <div className='h-full pt-20 pb-12 flex flex-col bg-slate-100 font-nunito'>
                    <form onSubmit={handleSubmit} className="font-nunito">
                        <div className='mt-14 max-w-80 mx-auto text-center mb-14'>
                            <h3 className='font-bold text-slate-900 text-5xl mb-4'>Welcome</h3>
                            <p className='text-slate-600 text-2xl font-semibold'>Please enter your credentials</p>
                        </div>
                        <Card className="max-w-[448px] mx-auto bg-white p-8">
                            <h6 className='text-center font-bold text-slate-900'>Login</h6>
                            <div className='mb-6'>
                                {/* <FormField>
                                    <FormItem className="mb-6">
                                        <FormLabel className='font-semibold text-sm text-slate-400 font-nunito'>
                                            Email
                                        </FormLabel>
                                        <Input
                                            className="mt-0 bg-white border-slate-300 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-green-500"
                                            type="text"
                                            name="email"
                                            placeholder="Email Address"
                                            value={formData.email}
                                            onChange={handleInputChange}
                                        />
                                    </FormItem>
                                </FormField>
                                <FormField>
                                    <FormItem>
                                        <FormLabel className='text-sm text-slate-400 font-nunito font-semibold'>
                                            Password
                                        </FormLabel>
                                        <div className="relative">
                                            <Input
                                                className="bg-white border-slate-300 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-green-500"
                                                type={show ? "text" : "password"}
                                                name="password"
                                                placeholder="Password"
                                                value={formData.password}
                                                onChange={handleInputChange}
                                            />
                                            {!show ?
                                                <EyeIcon
                                                    className="ml-auto absolute right-3 top-1/2 h-4 w-4 opacity-50 -translate-y-1/2 cursor-pointer text-slate-400"
                                                    onClick={toggleShow}
                                                /> :
                                                <EyeOffIcon
                                                    className="ml-auto absolute right-3 top-1/2 h-4 w-4 opacity-50 -translate-y-1/2 cursor-pointer text-slate-400"
                                                    onClick={toggleShow}
                                                />
                                            }
                                        </div>
                                    </FormItem>
                                </FormField>
                                <p className='text-green-700 mt-3 text-sm cursor-pointer w-fit'>
                                    Forgot password?
                                </p> */}
                            </div>
                            <Button
                                className="w-full bg-green-100 text-green-700 hover:bg-green-100 font-bold"
                                onClick={handleLoginClick}
                                type="button"
                            >
                                Login
                            </Button>
                        </Card>
                    </form>
                </div>
            </div>
        </>
    );
}

export default LoginPage;
