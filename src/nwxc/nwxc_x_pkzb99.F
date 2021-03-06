#if !defined(SECOND_DERIV) && !defined(THIRD_DERIV)
#if !defined(NWAD_PRINT)
C> \ingroup nwxc
C> @{
C>
C> \file nwxc_x_pkzb99.F
C> The Perdew, Kurth, Zupan, and Blaha exchange functional
C>
C> @}
#endif
#endif
C> \ingroup nwxc_priv
C> @{
C>
C> \brief The meta-GGA exchange functional by Perdew, Kurth, Zupan
C> and Blaha
C>
C> The meta-GGA exchange functional by Perdew, Kurth, Zupan and Blaha
C> that provides a self-interaction free energy [1,2].
C>
C> ### References ###
C>
C> [1] J.P. Perdew, S. Kurth, A. Zupan, P. Blaha,
C>     <i>"Accurate density functional with correct formal properties:
C>     A Step Beyond the Generalized Gradient Approximation"</i>,
C>     Phys. Rev. Lett. <b>82</b>, 2544-2547 (1999), DOI:
C>     <a href="http://dx.doi.org/10.1103/PhysRevLett.82.2544">
C>     10.1103/PhysRevLett.82.2544</a>.
C>
C> [2] J.P. Perdew, S. Kurth, A. Zupan, P. Blaha,
C>     <i>"Erratum: Accurate density functional with correct formal
C>     properties: A Step Beyond the Generalized Gradient
C>     Approximation"</i>,
C>     Phys. Rev. Lett. <b>82</b>, 5179-5179 (1999), DOI:
C>     <a href="http://dx.doi.org/10.1103/PhysRevLett.82.5179">
C>     10.1103/PhysRevLett.82.5179</a>.
C>
c     Perdew-Kurth-Zupan-Blaha '99 exchange functional 
c           META GGA
C         utilizes ingredients:
c                              rho   -  density
c                              delrho - gradient of density
c                              tau - K.S kinetic energy density
c                 cor only:    tauW - von Weiszacker kinetic energy density
c     References:
c     [a] J.P. Perdew, S. Kurth, A. Zupan and P. Blaha,
c         PRL 82, 2544 (1999).

#if !defined(SECOND_DERIV) && !defined(THIRD_DERIV)
#if defined(NWAD_PRINT)
      Subroutine nwxc_x_pkzb99_p(tol_rho, ipol, nq, wght, rho,
     &                         rgamma, tau, func)
#else
      Subroutine nwxc_x_pkzb99(tol_rho, ipol, nq, wght, rho,
     &                         rgamma, tau, func)
#endif
#elif defined(SECOND_DERIV) && !defined(THIRD_DERIV)
      Subroutine nwxc_x_pkzb99_d2(tol_rho, ipol, nq, wght, rho,
     &                         rgamma, tau, func)
#else
      Subroutine nwxc_x_pkzb99_d3(tol_rho, ipol, nq, wght, rho,
     &                         rgamma, tau, func)
#endif
c   
c$Id$
c
#include "nwad.fh"
c
      implicit none
c
#include "nwxc_param.fh"
c
c     Input and other parameters
c
      double precision tol_rho !< [Input] The lower limit on the density
      integer nq               !< [Input] The number of points
      integer ipol             !< [Input] The number of spin channels
      double precision wght    !< [Input] The weight of the functional
c
c     Charge Density 
c
      type(nwad_dble)::rho(nq,*) !< [Input] The density
c
c     Charge Density Gradient Norm
c
      type(nwad_dble)::rgamma(nq,*) !< [Input] The density gradient norm
c
c     Kinetic Energy Density
c
      type(nwad_dble)::tau(nq,*) !< [Input] The kinetic energy density
c
c     Functional values
c
      type(nwad_dble)::func(*) !< [Output] The functional value
c
c     Sampling Matrices for the XC Potential
c
c     double precision Amat(nq,*) !< [Output] Derivative wrt density
c     double precision Cmat(nq,*) !< [Output] Derivative wrt rgamma
c     double precision Mmat(nq,*) !< [Output] Derivative wrt tau
c
      type(nwad_dble)::tauN

      double precision  pi
      type(nwad_dble):: qtil, x, gamma, p
      type(nwad_dble)::  rho13, rho43, rho53, rho83,  mt, rrho
      double precision   F83, F23, F53, F43, F13
      double precision   G920 
      double precision   bigD, uk, ruk
      double precision    CX1, CX2, CX3, CX4
      double precision   P32, Ax
c     functional derivatives below
      double precision   d1p(3), d1x(3)
      double precision   rg2, d1mt(3)
      double precision   d1qtil(3), T1
c     functional derivatives above

      integer n

      parameter(uk=0.8040d0, bigD=0.113d0, ruk=1.d0/uk)
      parameter (F43=4.d0/3.d0, F13=1.d0/3.d0)
      parameter (F83=8.d0/3.d0, F23=2.d0/3.d0, F53=5.d0/3.d0)
      parameter (G920  =9.d0/20.d0 )
      parameter (CX1  =  10.d0/81.d0, 
     &     CX2  = 146.d0/2025.d0,
     &     CX3  = -73.d0/405.d0 )
      parameter (CX4= (bigD + ruk*CX1**2) )
c     
      pi=acos(-1d0)
      Ax = (-0.75d0)*(3d0/pi)**F13
      P32 = 1.d0/( 2.d0*(3.d0*pi**2)**(F23) ) 
      
c
      if (ipol.eq.1 )then
c
c     ======> SPIN-RESTRICTED <======
c     

         do 10 n = 1, nq
            if (rho(n,R_T).lt.tol_rho) goto 10

c  rho43= n*e_x^unif=exchange energy per electron for uniform electron gas
c       = n* Ax*n^(1/3)   or n*C*n^(1/3) 

            rho43 = Ax*rho(n,R_T)**F43  ! Ax*n^4/3
c           rrho = 1d0/rho(n,R_T)       ! reciprocal of rho
c           rho13 = F43*rho43*rrho   !functional deriv of rho43

            rho53 = rho(n,R_T)**F53
            rho83 = rho(n,R_T)**F83


C  Below we just sum up the LDA contribution to the functional
c           if (lfac) then
c              Amat(n,D1_RA) = Amat(n,D1_RA) + rho13*wght
               func(n) = func(n) + rho43*wght              
c           endif
c
            gamma = rgamma(n,G_TT)
c           gamma = delrho(n,1,1)*delrho(n,1,1) +
c    &              delrho(n,2,1)*delrho(n,2,1) +
c    &              delrho(n,3,1)*delrho(n,3,1)
c            gam12 = dsqrt(gamma)
c            if (.not.(nlfac.and.gam12.gt.tol_rho)) goto 10
            tauN = tau(n,T_T)

            p=0.5d0*P32*gamma/(rho83)
            qtil=(3.d0*tauN*P32/rho53)-G920-(p/12.d0)
c
c     Evaluate the GC part of Fx, i.e. mt = Fx(p,qtil) - 1
c

            x= CX1*p + CX2*qtil*qtil + CX3*qtil*p+ CX4*p*p

c           if (.not.(nlfac.and.x.gt.tol_rho)) goto 10

            
            mt = uk - uk/(1.d0 + x*ruk)


C      functional derivatives

c           rg2=1.d0/( (1.d0 + x*ruk)*(1.d0 + x*ruk) )
             
c    deriv wrt n, the density (for Amat)
c           d1p(1) = -F83*rrho*p

c           T1=3.d0*P32*tauN*(1.d0/rho53)
c           d1qtil(1) = -F53*T1*rrho - d1p(1)/12.d0

c           d1x(1) = CX1*d1p(1) + CX2*2.d0*qtil*d1qtil(1) +
c    &      CX3*(qtil*d1p(1) + p*d1qtil(1)) + CX4*2d0*p*d1p(1)

c           d1mt(1) = rg2*d1x(1)


c     deriv wrt gamma, the gradient (for Cmat)
c           d1p(2) = 0.5d0*P32/rho83
c           d1qtil(2) = -d1p(2)/12.d0

c           d1x(2) = CX1*d1p(2) + CX2*2d0*qtil*d1qtil(2) +
c    &      CX3*(qtil*d1p(2) + p*d1qtil(2)) + CX4*2d0*p*d1p(2)

c           d1mt(2) = rg2*d1x(2)


c     deriv wrt tau, the Kinetic Energy Density (for Mmat)

c           d1p(3) = 0.d0
c           d1qtil(3) = -d1p(2)/12.d0  am sure this is wrong

c           d1qtil(3) = 3.d0*P32/rho53

c           d1x(3) = CX2*2.d0*qtil*d1qtil(3) +
c    &      CX3*p*d1qtil(3)

c           d1mt(3) = rg2*d1x(3)



C    Below we add the MetaGGA correction to the LDA part from above

            func(n) = func(n) + rho43*mt*wght              

c           Amat(n,D1_RA) =Amat(n,D1_RA) + (mt*rho13+rho43*d1mt(1))*wght

c           Cmat(n,D1_GAA) = Cmat(n,D1_GAA) + 2.d0*(rho43*d1mt(2)*wght)
c                  check on this two or one

c           Mmat(n,D1_TA) = Mmat(n,D1_TA) +0.5d0*(rho43*d1mt(3)*wght)


 10      continue

      else
c
c        ======> SPIN-UNRESTRICTED <======

c
c  use spin density functional theory ie n-->2n
c                               Ex=(1/2)Ex[2*alpha] + (1/2)Ex[2*beta]

         do 20 n = 1, nq
            if (rho(n,R_A)+rho(n,R_B).lt.tol_rho) goto 20
c
c     Alpha            ALPHA               ALPHA
c
            if (rho(n,R_A).lt.tol_rho) goto 25
            rho43 = Ax*(2d0*rho(n,R_A))**F43 ! spin scaled
c           rrho = 0.5d0/rho(n,R_A)          ! spin scaled
c           rho13 = F43*rho43*rrho  !spin scaled & (1/2)factor

            rho53 = (2.d0*rho(n,R_A))**F53   ! spin scaled
            rho83 = (2.d0*rho(n,R_A))**F83   ! spin scaled
c  note all the "rho"  quantities ARE spin scaled, for later use

c           if (lfac) then
c              Amat(n,D1_RA) = Amat(n,D1_RA) + rho13*wght
               func(n) = func(n) + rho43*wght*0.5d0
c           endif
c
c           gamma = delrho(n,1,1)*delrho(n,1,1) +
c    &              delrho(n,2,1)*delrho(n,2,1) +
c    &              delrho(n,3,1)*delrho(n,3,1)
            gamma = rgamma(n,G_AA)
c NOTE  gamma above  is not spin scaled.  that is why
c                           -there is 4.d0*gamma in p
c                           -there is 2.0 in the gam12 term



c            gam12 = 2d0*dsqrt(gamma)
c            if (.not.(nlfac.and.gam12.gt.tol_rho)) goto 25

            tauN = 2.0d0*tau(n,T_A)
            
c
c     Evaluate the GC part of Fx, i.e. mt(x) = Fx - 1
c           

            p=0.5d0*P32*(4.d0*gamma)/rho83
            qtil=(3.d0*tauN*P32/rho53) - G920 - (p/12.d0)
 

            x= CX1*p + CX2*qtil*qtil + CX3*qtil*p+ CX4*p*p
c           if (.not.(nlfac.and.x.gt.tol_rho)) goto 25

c           rg2=1.d0/( (1.d0 + x*ruk)*(1.d0 + x*ruk) )

c  ccccccc   deriv wrt n, the density

c           d1p(1) = p*(-F83)*(2.d0*rrho)  ! spin scaled

c           T1=3.d0*P32*tauN/rho53        ! spin scaled
c           d1qtil(1) = -F53*T1*2.d0*rrho - d1p(1)/12.d0

c           d1x(1) = CX1*d1p(1) + CX2*2.d0*qtil*d1qtil(1) +
c    &      CX3*(qtil*d1p(1) + p*d1qtil(1)) + CX4*2d0*p*d1p(1)

c           d1mt(1) = rg2*d1x(1)


c     deriv wrt gamma, the gradient
c           d1p(2) = 0.5d0*P32*4.d0/rho83     ! spin scaled
c           d1qtil(2) = -d1p(2)/12.d0        !spin scaled

c           d1x(2) = CX1*d1p(2) + CX2*2d0*qtil*d1qtil(2) +
c    &      CX3*(qtil*d1p(2) + p*d1qtil(2)) + CX4*2d0*p*d1p(2)

c           d1mt(2) = rg2*d1x(2)


c     deriv wrt tau, the Kinetic Energy Density

c             d1p(3) = 0.d0  term shown for completeness
c           d1qtil(3) = 3.d0*P32/rho53

c           d1x(3) = CX2*2.d0*qtil*d1qtil(3) +
c    &      CX3*p*d1qtil(3)

c           d1mt(3) = rg2*d1x(3)

            mt = uk - uk/(1.d0 + x*ruk)

            func(n) = func(n) + rho43*mt*wght*0.5d0

c           Amat(n,D1_RA)=Amat(n,D1_RA)
c    &                   +(mt*rho13 + 0.5d0*rho43*d1mt(1))*wght
c       note that the (.5) is built into the rho13 term already
c       hence we only need to put it onto the second term in Amat


c           Cmat(n,D1_GAA) = Cmat(n,D1_GAA) + (0.5d0*rho43*d1mt(2)*wght)
c           Mmat(n,D1_TA)=Mmat(n,D1_TA)+1.0d0*(0.5d0*rho43*d1mt(3)*wght)

          
c
c     Beta               BETA           BETA
c
 25         continue

            if (rho(n,R_B).lt.tol_rho) goto 20
            rho43 = Ax*(2d0*rho(n,R_B))**F43  ! Ax (2 nBeta)^4/3
c           rrho = 0.5d0/rho(n,R_B)           ! 1/(2 nBeta)
c           rho13 = F43*rho43*rrho   !spin scaled func deriv of rho43  

            rho53 = (2.d0*rho(n,R_B))**F53
            rho83 = (2.d0*rho(n,R_B))**F83

C  note all "rho" quantities above are spin scaled for later use

c           if (lfac) then
c             Amat(n,D1_RB) = Amat(n,D1_RB) + rho13*wght
              func(n) = func(n) + rho43*wght*0.5d0
c           endif
c

c           gamma = delrho(n,1,2)*delrho(n,1,2) +
c    &              delrho(n,2,2)*delrho(n,2,2) +
c    &              delrho(n,3,2)*delrho(n,3,2)
            gamma = rgamma(n,G_BB)
c NOTE  gamma above  is not spin scaled.  that is why
c                           -there is 4.d0*gamma in p term
c                           -there is 2.0 in the gam12 term


c            gam12 = 2d0*dsqrt(gamma)
c            if (.not.(nlfac.and.gam12.gt.tol_rho)) goto 20

            tauN = 2.0d0*tau(n,T_B)
            
c
c     Evaluate the GC part of F(x), i.e. mt(x) = Fx - 1
c
         

            p=0.5d0*P32*(4.d0*gamma)/rho83
            qtil=(3.d0*tauN*P32/rho53) - G920 - (p/12.d0)


            x= CX1*p + CX2*qtil*qtil + CX3*qtil*p+ CX4*p*p


c           if (.not.(nlfac.and.x.gt.tol_rho)) goto 20


c           rg2=1.d0/( (1.d0 + x*ruk)*(1.d0 + x*ruk) )

c  ccccccc   deriv wrt n, the density

c           d1p(1) = p*(-F83)*(2.d0*rrho)  ! spin scaled

c           T1=3.d0*P32*tauN/rho53        ! spin scaled
c           d1qtil(1) = -F53*T1*2.d0*rrho - d1p(1)/12.d0

c           d1x(1) = CX1*d1p(1) + CX2*2.d0*qtil*d1qtil(1) +
c    &      CX3*(qtil*d1p(1) + p*d1qtil(1)) + CX4*2d0*p*d1p(1)

c           d1mt(1) = rg2*d1x(1)


c     deriv wrt gamma, the gradient
c           d1p(2) = 0.5d0*P32*4.d0/rho83     ! spin scaled
c           d1qtil(2) = -d1p(2)/12.d0        !spin scaled

c           d1x(2) = CX1*d1p(2) + CX2*2d0*qtil*d1qtil(2) +
c    &      CX3*(qtil*d1p(2) + p*d1qtil(2)) + CX4*2d0*p*d1p(2)

c           d1mt(2) = rg2*d1x(2)



c     deriv wrt tau, the Kinetic Energy Density

C             d1p(3) = 0.d0  included for completeness
c           d1qtil(3) = 3.d0*P32/rho53


c           d1x(3) = CX2*2.d0*qtil*d1qtil(3) +
c    &      CX3*p*d1qtil(3)

c           d1mt(3) = rg2*d1x(3)
             
            mt = uk - uk/(1.d0 + x*ruk)
            
            func(n) = func(n) + rho43*mt*wght*0.5d0

c           Amat(n,D1_RB)=Amat(n,D1_RB)
c    &                   +(mt*rho13 + 0.5d0*rho43*d1mt(1))*wght
c       note that the (.5) is built into the rho13 term already
c       hence we only need to put it onto the second term in Amat

c           Cmat(n,D1_GBB) = Cmat(n,D1_GBB) + 0.5d0*rho43*d1mt(2)*wght
c           Mmat(n,D1_TB) = Mmat(n,D1_TB) + 0.5d0*rho43*d1mt(3)*wght

20      continue
      endif
c
      return
      end
#if !defined(NWAD_PRINT)
#define NWAD_PRINT
c
c     Include and compile for 2nd derivatives
c
#include "nwxc_x_pkzb99.F"
#endif
#if !defined(SECOND_DERIV)
#define SECOND_DERIV
c
c     Include and compile for 2nd derivatives
c
#include "nwxc_x_pkzb99.F"
#endif
#if !defined(THIRD_DERIV)
#define THIRD_DERIV
c
c     Include and compile for 3rd derivatives
c
#include "nwxc_x_pkzb99.F"
#endif
#undef NWAD_PRINT
C> @}
