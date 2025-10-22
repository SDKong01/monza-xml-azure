import Image from 'next/image';
import React from 'react';

const PublicHeader = () => {
    return (
        <header className="h-20 bg-white flex justify-center items-center absolute top-0 left-0 right-0 shadow-headerShadow">
            <div className="relative h-16 w-80">
                <Image
                    src="/kainam-logo.png"
                    alt="KAINAM Logo"
                    fill
                    className="object-contain"
                />
            </div>
        </header>
    )
}

export default PublicHeader;
