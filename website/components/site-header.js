import Image from 'next/image';
import Link from 'next/link';

export default function SiteHeader({ copy }) {
  return (
    <header className="nav">
      <Link className="brand" href="/">
        <Image
          className="brand-mark"
          src="/icons/Icon-512.png"
          alt={copy.logoAlt}
          width={46}
          height={46}
          priority
        />
        <span>{copy.brand}</span>
      </Link>
      <nav className="nav-links">
        <a className="button" href={copy.appUrl}>{copy.navOpenApp}</a>
      </nav>
    </header>
  );
}
